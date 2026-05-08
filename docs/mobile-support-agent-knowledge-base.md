# Mobile Support Agent Technical Skills and Knowledge Base

## Purpose

This knowledge base defines the technical scope, workflows, diagnostics, and communication standards for a Mobile Support Agent who helps developers implement, integrate, update, and troubleshoot LawyerSys mobile features.

The agent supports the Flutter mobile app in `MobileApp/`, the ASP.NET Core API in `LawyerSys/`, and related integrations such as Firebase Cloud Messaging, Sentry, authentication, file/document APIs, and localization.

## Technical Proficiency Matrix

| Domain | Required Capability | Working Knowledge | Evidence of Proficiency |
|--------|---------------------|-------------------|-------------------------|
| Flutter and Dart | Understand Flutter 3.x, Dart 3.x, widgets, navigation, async flows, null safety, package management, and build modes. | `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`, `flutter build apk`, `flutter build ios`. | Can identify whether a failure is caused by widget state, dependency setup, platform configuration, generated code, or runtime data. |
| iOS | Understand Xcode projects, signing, provisioning, entitlements, push notification capabilities, `Info.plist`, CocoaPods, simulator/device differences, and iOS permission prompts. | Xcode logs, `pod install`, `flutter clean`, `flutter build ios`, APNs setup, Firebase iOS configuration. | Can distinguish signing failures from runtime crashes, missing plist permissions, APNs token issues, and dependency build failures. |
| Android | Understand Gradle, Android SDK levels, manifests, permissions, Firebase config, Play services, emulator/device behavior, and release signing. | Android Studio Logcat, `android/app/build.gradle`, `AndroidManifest.xml`, `google-services.json`, keystores, ABI splits. | Can isolate manifest, Gradle, SDK, permission, notification channel, and release-only problems. |
| REST API Integration | Understand endpoints, HTTP methods, headers, auth tokens, status codes, pagination, file uploads, error contracts, and retry behavior. | Dio interceptors, bearer tokens, multipart requests, Postman collections, server logs, API contracts. | Can map failed mobile calls to endpoint contracts and determine whether the fault is client payload, authentication, server validation, or network environment. |
| GraphQL Integration | Understand schema introspection, queries, mutations, variables, fragments, pagination, auth headers, and typed response handling. | GraphQL playgrounds, Postman/Insomnia GraphQL requests, generated models if introduced. | Can diagnose schema mismatch, field nullability, missing variables, authorization, and backward compatibility problems. |
| SDK Implementation | Understand Firebase, Crashlytics/Sentry, push notification SDKs, local auth, secure storage, file pickers, and native permissions. | Firebase console, Sentry releases, SDK initialization order, platform files, app lifecycle callbacks. | Can verify SDK config files, initialization, permissions, tokens, environment separation, and release symbol mapping. |
| Authentication and Security | Understand JWT bearer auth, refresh flows, secure storage, biometric auth, tenant context, token expiry, and protected routes. | FlutterSecureStorage, API auth middleware, token interceptors, 401/403 behavior. | Can diagnose invalid token persistence, stale sessions, permission mismatches, and missing tenant/user context. |
| Localization | Understand English/Arabic app resources, RTL behavior, generated localization classes, and missing key failures. | ARB files, `flutter_localizations`, generated `AppLocalizations`. | Can detect missing translation keys, duplicate localization files, RTL layout defects, and stale generated classes. |
| State Management | Understand BLoC/Riverpod patterns used by the app, state transitions, repository boundaries, and error state rendering. | Bloc events/states, repository mocks, widget tests. | Can determine whether data disappeared because of API response shape, state transition defects, or UI rendering assumptions. |
| Version Control | Understand Git branching, commits, diffs, merge conflicts, PR review, and release tags. | `git status`, `git diff`, `git log`, feature branches, pull requests. | Can produce support notes tied to exact commits, impacted files, reproduction branches, and rollback candidates. |
| Backend Context | Understand ASP.NET Core Web API, EF Core, Identity, JWT, PostgreSQL, and service-layer contracts. | `dotnet test`, controller/service contracts, API validation models. | Can identify when a mobile issue requires backend contract clarification or server-side fix. |

## Feature Implementation Workflow

Use this workflow when a developer is deploying or integrating a new mobile feature.

### 1. Intake and Scope Confirmation

- Identify the feature name, business flow, target users, and supported platforms.
- Confirm whether the feature is new, a parity implementation from the web client, or an update to an existing mobile module.
- Capture the expected route, screens, API endpoints, permissions, localization keys, analytics/crash reporting requirements, and offline expectations.
- Link the feature to the relevant spec, task, issue, or PR.

### 2. Prerequisite Checks

- Confirm the local environment:
  - Flutter SDK version.
  - Dart SDK version.
  - Android Studio and Android SDK versions.
  - Xcode version and selected command line tools for iOS.
  - Device/emulator OS version.
- Confirm dependencies are installed:
  - Run `flutter pub get`.
  - Run code generation if required: `flutter pub run build_runner build --delete-conflicting-outputs`.
  - Verify Firebase files exist when push notifications or analytics are involved:
    - `MobileApp/android/app/google-services.json`
    - `MobileApp/ios/Runner/GoogleService-Info.plist`
- Confirm backend availability:
  - API base URL points to the intended environment.
  - Auth credentials are valid.
  - Required seed data exists.
  - Endpoint contracts match the mobile request and response models.

### 3. Environment Configuration

- Verify `MobileApp/lib/core/api/api_constants.dart` or the active environment provider points to the correct API host.
- Confirm auth token storage and refresh behavior with `FlutterSecureStorage`.
- Confirm platform permissions:
  - iOS: `Info.plist` keys for camera, photos, documents, notifications, biometrics, or location as needed.
  - Android: `AndroidManifest.xml` permissions and runtime permission prompts.
- Confirm SDK initialization order in `main.dart`, especially for Firebase, Sentry, localization, dependency injection, and app bootstrap.
- Confirm localization files include the required English and Arabic keys.

### 4. Implementation Review

- Validate feature folder structure follows project conventions:
  - `models/`
  - `repositories/`
  - `bloc/` or state-management equivalent.
  - `screens/`
  - `widgets/`
- Check models against API contracts:
  - Required fields.
  - Nullable fields.
  - Date/time formats.
  - Enum values.
  - Pagination metadata.
  - Error response shape.
- Check UI behavior:
  - Loading, empty, success, error, offline, and permission-denied states.
  - Arabic/RTL rendering.
  - Small screen layout.
  - Back navigation and deep linking if applicable.
- Check file or document features:
  - Multipart upload field names.
  - File size limits.
  - MIME type restrictions.
  - Download authorization.
  - Local cache cleanup.

### 5. Validation Steps

- Run static validation:
  - `flutter analyze`
  - `dart format .`
- Run tests:
  - `flutter test`
  - Targeted widget or repository tests for the feature.
- Validate API behavior:
  - Use Postman or equivalent to confirm the endpoint succeeds outside the app.
  - Compare app payloads with the known-good request.
  - Confirm status codes and error bodies are handled correctly.
- Validate devices:
  - Android emulator.
  - Android physical device when native permissions, notifications, camera, files, or biometrics are involved.
  - iOS simulator.
  - iOS physical device for push notifications, APNs, biometrics, camera, and release signing.
- Validate release mode for issues that do not appear in debug mode:
  - `flutter build apk --release --split-per-abi`
  - `flutter build ios --release`

### 6. Escalation Criteria

Escalate to backend engineering when:

- API documentation and actual responses disagree.
- The same request succeeds in one environment and fails in another.
- Server returns 5xx or unhandled validation responses.
- Authorization rules conflict with expected user roles.
- Required mobile fields cannot be derived from current endpoints.

Escalate to mobile engineering when:

- Crash is reproducible in the app but not in direct API calls.
- Platform permission or SDK initialization is wrong.
- State transitions drop valid data.
- UI renders invalid states despite valid repository responses.
- Release builds behave differently from debug builds.

Escalate to DevOps/release engineering when:

- Signing, certificates, provisioning, CI, package publishing, environment secrets, or app store deployment fails.
- Firebase, APNs, or Sentry project credentials are missing or environment-specific.

## Update and Migration Protocol

Use this protocol for dependency upgrades, SDK updates, API contract changes, and platform migrations.

### 1. Change Classification

Classify the update before troubleshooting:

- Patch update: bug fix with no expected contract changes.
- Minor update: new capability with possible additive API or SDK behavior.
- Major update: potential breaking changes.
- Platform update: Android SDK, iOS deployment target, Gradle, CocoaPods, Xcode, Firebase, or Flutter SDK changes.
- API migration: endpoint path, payload, auth, pagination, validation, or response model changes.

### 2. Pre-Migration Checklist

- Capture current versions:
  - Flutter SDK and Dart SDK.
  - `pubspec.yaml` dependencies.
  - Android Gradle plugin and Gradle wrapper.
  - Kotlin version if present.
  - iOS pods and deployment target.
  - Firebase/Sentry SDK versions.
- Capture current behavior:
  - Screens affected.
  - API endpoints affected.
  - Known passing tests.
  - Baseline crash rate if Crashlytics/Sentry data exists.
- Create or confirm a feature branch.
- Review release notes, migration guides, and deprecation notices.
- Identify rollback strategy:
  - Dependency pin.
  - API compatibility shim.
  - Feature flag.
  - Server-side backward-compatible response.

### 3. Breaking Change Handling

- Map old contract to new contract:
  - Removed fields.
  - Renamed fields.
  - New required fields.
  - Changed enum values.
  - Changed date formats.
  - Changed pagination envelope.
  - Changed auth/role requirements.
- Add compatibility handling when older app versions may still call the API.
- Avoid removing mobile-supported fields until app adoption is confirmed.
- For SDK changes, verify:
  - Initialization signatures.
  - Required native configuration.
  - Permission changes.
  - Android/iOS minimum supported versions.
  - Build-system changes.
- For localization changes, verify every new key exists in English and Arabic.

### 4. Deprecation Notice Procedure

Each deprecation notice should include:

- Deprecated API, SDK, screen, route, field, or behavior.
- Replacement API, SDK, field, or workflow.
- First version where deprecation applies.
- Planned removal version or date.
- Risk to existing mobile versions.
- Required developer action.
- Test cases that prove both old and new behavior work during the transition.

### 5. Backward Compatibility Rules

- Prefer additive API changes over breaking response changes.
- Keep old fields available until the minimum supported app version no longer uses them.
- Support both old and new enum values during rollout when possible.
- Treat nullable response changes as breaking if the UI assumes non-null data.
- Do not require app updates for server-only changes unless explicitly planned.
- Keep error response contracts stable so mobile error handling remains predictable.

### 6. Post-Migration Validation

- Run `flutter analyze` and `flutter test`.
- Run targeted tests for migrated features.
- Build Android and iOS release artifacts when native dependencies changed.
- Smoke test login, dashboard, affected feature routes, push notifications, file upload/download, and localization.
- Review Sentry/Firebase crash reports after rollout.
- Confirm API logs show expected request shape from the migrated app.

## Developer Communication Framework

The Mobile Support Agent should translate ambiguous reports into reproducible, actionable tickets.

### Required Intake Fields

Ask developers for:

- Feature or screen name.
- Expected behavior.
- Actual behavior.
- Reproduction steps.
- Environment:
  - App version/build number.
  - Branch or commit SHA.
  - Flutter/Dart version.
  - Platform: iOS or Android.
  - OS version.
  - Device model or emulator.
  - API environment: local, staging, production.
  - User role and tenant if applicable.
- Logs:
  - Flutter console logs.
  - Xcode logs for iOS.
  - Android Studio Logcat for Android.
  - API response body and status code.
  - Sentry/Firebase Crashlytics event ID if available.
- Network evidence:
  - Request URL.
  - HTTP method.
  - Headers excluding secrets.
  - Request body with sensitive data redacted.
  - Response body with sensitive data redacted.

### Log Request Template

Use this when requesting more diagnostic data:

```text
Please attach the following so we can isolate the failure:

- App version/build number:
- Branch/commit:
- Platform and OS version:
- Device/emulator:
- API environment:
- User role/tenant:
- Exact reproduction steps:
- Expected result:
- Actual result:
- Flutter console logs:
- Xcode/Logcat logs:
- API request method and URL:
- API status code and response body:
- Sentry/Firebase event ID, if available:

Please redact access tokens, passwords, client names, case numbers, and private document contents.
```

### Bug-to-Ticket Translation

Convert bug reports into tickets with this structure:

```text
Title:
[Mobile][Platform][Feature] Short failure summary

Impact:
Who is blocked, how often it occurs, and whether there is a workaround.

Environment:
App version, platform, OS version, device, API environment, branch/commit.

Steps to Reproduce:
1. ...
2. ...
3. ...

Expected Result:
What should happen.

Actual Result:
What happened instead.

Evidence:
Logs, screenshots, API request/response, crash event IDs.

Suspected Area:
API contract, auth, state management, UI rendering, native platform config, SDK setup, or release pipeline.

Acceptance Criteria:
- The issue is fixed for the reported platform.
- Regression coverage is added or updated.
- Error handling is user-safe.
- Arabic/RTL behavior is checked when UI is affected.
```

### Communication Standards

- State facts separately from assumptions.
- Reproduce before assigning blame to mobile, backend, infrastructure, or SDK vendors.
- Request the smallest missing artifact needed to advance the investigation.
- Redact secrets and private legal data from all tickets and logs.
- Include file paths, endpoints, event IDs, and command output where available.
- Mark severity based on user impact:
  - Critical: data loss, security issue, login blocked, app-wide crash.
  - High: core legal workflow blocked with no workaround.
  - Medium: feature degraded with workaround.
  - Low: cosmetic, copy, non-blocking edge case.

## Diagnostic Toolkit

| Tool | Primary Use | How to Use It | What It Helps Isolate |
|------|-------------|---------------|------------------------|
| Flutter CLI | Build, run, analyze, and test the mobile app. | Run `flutter doctor`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`. | SDK setup, dependency issues, compile errors, analyzer failures, test regressions. |
| Dart DevTools | Inspect runtime performance, widget tree, memory, logs, and network activity. | Launch from `flutter run` or IDE tooling. | Rebuild loops, memory leaks, state issues, layout problems. |
| Android Studio Logcat | Inspect Android runtime logs and crashes. | Filter by package name, exception type, Firebase, network, or permission errors. | Android permission failures, native crashes, SDK initialization errors, notification issues. |
| Xcode Console | Inspect iOS runtime logs and signing/runtime issues. | Run from Xcode or attach to device logs. | iOS permission failures, APNs issues, entitlement problems, native plugin crashes. |
| Charles Proxy | Capture and inspect mobile HTTP/HTTPS traffic. | Configure device proxy, install Charles SSL certificate, enable SSL proxying for API host. | Incorrect URLs, headers, payloads, status codes, TLS/proxy issues, unexpected redirects. |
| Proxyman | Alternative network proxy for macOS/iOS workflows. | Configure simulator or device proxy and inspect HTTPS traffic. | Same network diagnostics as Charles, especially for iOS developers. |
| Postman | Reproduce API calls outside the app. | Send the same method, URL, headers, and body as the app. | API contract errors, auth failures, backend validation problems. |
| Insomnia | REST and GraphQL request validation. | Test GraphQL queries/mutations or REST endpoints with environment variables. | Schema mismatch, auth headers, request shape problems. |
| Firebase Console | Validate FCM, app config, and notification delivery. | Check app registration, FCM tokens, message delivery, platform config files. | Missing config files, wrong app IDs, notification delivery failures. |
| Firebase Crashlytics | Crash triage if Crashlytics is used for a given build. | Check event stack traces, affected versions, device distribution, breadcrumbs. | Native crashes, release-only crashes, recurring crash signatures. |
| Sentry | Runtime error tracking and release health. | Search by release, user, environment, screen, or event ID. | Dart exceptions, API error context, breadcrumbs, release regressions. |
| Browser/API Server Logs | Correlate mobile requests with backend behavior. | Match request timestamp, user ID, endpoint, status code, correlation ID. | Server errors, validation failures, auth/role mismatches, tenant context problems. |
| Git | Identify introduced changes and affected files. | Use `git status`, `git diff`, `git log`, `git blame` when needed. | Regression source, merge errors, version drift, rollback candidates. |
| Device Settings | Validate permissions, network, notifications, and biometrics. | Reset permissions, clear app data, reinstall app, check notification settings. | Stale tokens, denied permissions, disabled notifications, local data corruption. |

## Common Failure Patterns

| Pattern | Symptoms | Likely Cause | Resolution |
|---------|----------|--------------|------------|
| Wrong API base URL | Requests fail, hit production instead of staging, or return unexpected data. | Environment config points to the wrong host. | Verify API constants/environment provider, rebuild app, confirm request host in proxy logs. |
| Missing bearer token | API returns 401. | Token not saved, expired, missing from Dio interceptor, or user is logged out. | Confirm login flow, secure storage, interceptor headers, token expiry, and refresh behavior. |
| User lacks permission | API returns 403. | Role/tenant does not allow the action. | Confirm user role, tenant context, backend policy, and expected feature access. |
| Model field mismatch | Screen crashes or renders empty data after successful 200 response. | JSON key changed, field nullability changed, enum value unknown, or date format changed. | Compare API response to Dart model, update parsing, add null-safe fallback, and add regression test. |
| Pagination not advancing | Infinite scroll repeats the first page or stops early. | Incorrect page index, missing continuation metadata, or stale state. | Verify request parameters, response metadata, and BLoC state transitions. |
| Multipart upload failure | File upload returns 400/415/500. | Wrong form field name, MIME type, file size, auth header, or content type. | Compare with API contract, test in Postman, inspect mobile request in Charles, validate file limits. |
| Download opens blank file | Document download succeeds but viewer fails. | Incorrect MIME type, corrupted bytes, auth redirect saved as file, or unsupported viewer. | Inspect response headers/body, verify file bytes, handle auth failures before saving. |
| Push token not generated | Notifications do not arrive. | Firebase config missing, permissions denied, simulator limitation, APNs not configured, or SDK initialization order wrong. | Verify platform config, request permissions, test physical iOS device, check FCM/APNs setup. |
| Notification received but tap does nothing | Notification appears, but app does not navigate. | Missing message handler or route mapping. | Verify foreground/background/tap handlers and payload route fields. |
| iOS build fails after dependency update | CocoaPods or Xcode errors. | Pod repo stale, deployment target too low, plugin requires newer iOS, or signing config invalid. | Run `pod install`, update deployment target, review plugin migration notes, verify signing. |
| Android build fails after dependency update | Gradle errors or duplicate classes. | Incompatible Gradle/Kotlin/plugin versions, min SDK conflict, or dependency collision. | Review plugin requirements, align Gradle/Kotlin versions, inspect dependency tree, update SDK config. |
| Works in debug, fails in release | Release crash, blank screen, or missing network data. | Obfuscation, missing permissions, release signing, tree shaking, or environment difference. | Build release locally, inspect logs, confirm release config and SDK initialization. |
| Arabic text missing or broken | Placeholder keys, English fallback, layout overflow, or wrong direction. | Missing ARB key, stale generated localization, hard-coded string, or RTL layout issue. | Add keys in English and Arabic, regenerate localization, replace hard-coded text, test RTL. |
| Biometric login unavailable | Feature hidden or always fails. | Device lacks biometrics, permissions not configured, secure credential missing, or platform config incomplete. | Check device capability, local auth config, secure storage state, and fallback login flow. |
| Stale user session after logout | Previous user data appears after another login. | Cache, BLoC state, secure storage, or repository data not cleared. | Clear auth token, user profile, feature caches, and reset state on logout. |
| Crash without visible error | App closes or Sentry captures exception. | Unhandled async error, null assertion, plugin exception, or platform callback failure. | Pull stack trace from Sentry/Crashlytics, reproduce with logs, add guarded error handling and test. |
| API works in Postman but fails in app | Same endpoint succeeds outside mobile. | Header mismatch, payload serialization difference, URL encoding, TLS/proxy, or environment mismatch. | Compare exact raw request from proxy with Postman request. |
| App works on emulator but not physical device | Network or platform-specific failure. | Localhost misuse, device cannot reach dev server, permission state, OS version difference. | Use reachable LAN URL, confirm firewall, reset permissions, test on matching OS versions. |
| App works on Android but not iOS | Platform-specific SDK or permission problem. | Missing plist keys, APNs/capability issue, iOS file picker behavior, or ATS/network policy. | Review iOS platform files, Xcode logs, entitlements, and SDK setup. |
| App works on iOS but not Android | Platform-specific manifest or Gradle problem. | Missing Android permission, notification channel, file provider, SDK level, or Gradle config. | Review manifest, Logcat, Gradle files, and Android-specific plugin setup. |
| Feature route crashes | Navigation fails when opening a screen. | Route not registered, missing argument, dependency injection missing, or provider not in scope. | Confirm route registration, argument model, DI setup, and provider/BLoC availability. |
| Empty screen with no error | UI shows no data and no message. | Empty state not implemented, error swallowed, repository returns default empty list, or state not emitted. | Add explicit loading/error/empty states, inspect repository result, and verify state transitions. |
| Time/date appears wrong | Hearings, tasks, or deadlines display shifted times. | UTC/local conversion, server timezone, device locale, or date parsing mismatch. | Confirm API timezone contract, parse consistently, display using user locale, add date tests. |
| Dependency conflict after `pub get` | Version solving fails. | Incompatible package constraints. | Review `pubspec.yaml`, use compatible package versions, run `flutter pub outdated`, update with migration notes. |
| Generated files are stale | Build errors for missing generated classes or old fields. | Code generation was not run after model or localization change. | Run build runner or localization generation, clean conflicting outputs, commit generated artifacts if repo policy requires. |

## First-Contact Resolution Checklist

- Confirm the issue is reproducible or gather enough logs to explain why not.
- Identify whether the failure is client, API, platform, SDK, environment, or release pipeline.
- Check the request/response boundary before changing mobile code.
- Verify platform-specific files when permissions, notifications, files, camera, or biometrics are involved.
- Confirm English and Arabic behavior for UI-facing changes.
- Provide developers with exact next actions, impacted files, commands to run, and validation criteria.

## Reference Commands

Run from `MobileApp/` unless otherwise noted:

```bash
flutter doctor
flutter pub get
flutter analyze
dart format .
flutter test
flutter test --coverage
flutter run
flutter build apk --release --split-per-abi
flutter build ios --release
```

Run from the repository root for backend validation:

```bash
dotnet test
```

