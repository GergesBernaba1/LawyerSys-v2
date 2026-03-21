# Research Documentation: Flutter Mobile App

**Feature**: 003-flutter-mobile-app  
**Date**: 2026-03-20  
**Phase**: 0 (Research & Technology Decisions)

## Overview

This document captures research findings and technology decisions for the LawyerSys Flutter mobile application. All decisions are informed by the feature specification requirements, constitution constraints, and Flutter ecosystem best practices for 2026.

## Core Technology Stack

### Decision: Flutter 3.x with Dart 3.x

**Rationale**:
- Flutter provides true cross-platform development for iOS and Android from single codebase, reducing development and maintenance costs
- Dart 3.x brings sound null safety, pattern matching, and records for safer, more expressive code
- Flutter's hot reload enables rapid UI iteration essential for bilingual RTL/LTR layout testing
- Material Design 3 widgets provide consistent, accessible UI components out-of-box
- Large ecosystem with mature packages for all required features (HTTP client, local storage, push notifications, biometric auth)

**Alternatives Considered**:
- React Native: Rejected due to bridge performance overhead and weaker RTL layout support
- Native iOS/Android: Rejected due to double implementation cost and slower iteration velocity
- Xamarin/MAUI: Rejected due to smaller ecosystem and less mature cross-platform UI framework

**Target Platforms**: iOS 13+ and Android 8.0+ per FR-027

---

## State Management

### Decision: flutter_bloc (BLoC pattern)

**Rationale**:
- BLoC (Business Logic Component) pattern separates UI from business logic, enabling robust testing (constitution requirement IV)
- Reactive streams provide predictable state changes essential for offline sync and conflict resolution
- flutter_bloc package provides standardized patterns (BlocProvider, BlocBuilder, BlocListener) reducing code variability across features
- Excellent debugging support via bloc_observer for logging state transitions to meet FR-018 audit requirements
- Well-documented and widely adopted in Flutter community, easing onboarding for future developers

**Alternatives Considered**:
- Riverpod: Rejected as overkill for this app's complexity; provider-based pattern less intuitive for offline sync queue management
- Provider: Rejected due to lack of built-in event sourcing for auditing state changes
- GetX: Rejected due to anti-pattern concerns (service locator, tight coupling) and inferior testability

**Implementation Pattern**:
- Each feature (authentication, dashboard, cases, hearings, customers, documents) gets dedicated BLoC
- Blocs emit states representing loading, success, error, offline conditions
- Events represent user actions (login, search, refresh) and system triggers (network restored, sync completed)

---

## HTTP Client & API Integration

### Decision: dio (HTTP client library)

**Rationale**:
- dio provides interceptor architecture enabling centralized JWT token injection (auth_interceptor) and tenant context headers (tenant_interceptor)
- Built-in request/response transformation for consistent error handling across all API calls
- Native support for FormData multipart uploads needed for document/file operations (FR-016)
- Configurable timeouts, retry policies, and cancellation tokens for robust network handling
- Better error messages than http package, aiding FR-025 (meaningful error messages in selected language)

**Alternatives Considered**:
- http package: Rejected due to lack of interceptors, requiring manual token/tenant handling in every repository
- Chopper: Rejected as code generation overhead unnecessary for straightforward REST API consumption
- graphql_flutter: N/A as backend uses REST, not GraphQL

**API Contract**:
- Base URL: Configured in api_constants.dart (e.g., https://api.lawyersys.example.com)
- Authentication: JWT Bearer token in Authorization header
- Tenant Context: X-Tenant-Id header on every request (per constitution tenant isolation requirement)
- Response Format: JSON with standardized error structure matching existing web client expectations

---

## Local Storage & Offline Functionality

### Decision: sqflite for offline database, flutter_secure_storage for tokens, shared_preferences for settings

**Rationale**:

**sqflite (SQLite)**:
- Relational database enables complex queries (JOINs on cases-customers-hearings) matching server-side data model
- Transactional support ensures data consistency during offline operations and sync
- SQL schema mirrors backend entities (Case, Customer, Hearing, Court, Employee, Document) simplifying sync logic
- Storage quota management straightforward (check database file size against FR-013 limits: 100MB default, 50-500MB configurable)
- Mature Flutter plugin with excellent performance on both iOS and Android

**flutter_secure_storage**:
- Platform-native encrypted storage (iOS Keychain, Android Keystore) for JWT access/refresh tokens
- Meets constitution requirement II (Secure And Auditable Access By Default)
- Tokens not accessible to other apps or system debuggers
- Automatic token retrieval on app restart for FR-017 (7-day session persistence)

**shared_preferences**:
- Simple key-value store for non-sensitive user preferences (language selection, notification settings, offline cache size preference)
- Lightweight and fast for app startup performance

**Alternatives Considered**:
- Hive: Rejected due to NoSQL model complicating relational queries (e.g., finding all hearings for cases in a specific court)
- Isar: Rejected as newer with smaller community; migration path unclear if issues arise
- Sembast: Rejected due to JSON document store; less efficient for structured legal domain data

**Offline Sync Strategy**:
- Write queue: Changes made offline stored in sync_queue table with operation type (INSERT, UPDATE, DELETE), entity type, entity ID, payload JSON, timestamp, and tenant context
- On network restoration: Process queue in chronological order, sending each operation to server
- Conflict detection: Server returns 409 Conflict with current server state if resource was modified since last sync
- Conflict resolution: conflict_resolver.dart presents side-by-side UI (field-by-field comparison) per clarification (merge with user review and selective override)

---

## Push Notifications

### Decision: firebase_messaging (FCM for Android, APNs via FCM for iOS)

**Rationale**:
- Firebase Cloud Messaging supports both Android (native FCM) and iOS (APNs backend) with unified Flutter API
- Zero cost for reasonable volumes (LawyerSys use case: notifications for hearings, case assignments, not massive broadcast)
- Proven reliability for time-sensitive notifications (FR-015 requires < 30s delivery per SC-006)
- Background/foreground notification handling, notification taps routing to specific screens
- Token management (device registration) handled by SDK, simplifying backend integration

**Backend Integration**:
- Mobile app sends FCM device token to ASP.NET Core API on login
- Backend stores token in user record associated with tenant context (preventing cross-tenant notification leakage)
- Backend uses FirebaseAdmin SDK to send targeted notifications when events occur (new hearing scheduled, case assigned, task reminder)

**Alternatives Considered**:
- OneSignal: Rejected as third-party SaaS introducing additional vendor dependency; FCM free tier sufficient
- Native APNs/FCM direct: Rejected due to duplicated implementation complexity; firebase_messaging abstracts platform differences
- SignalR realtime: Rejected for push notifications as requires app in foreground; suitable for in-app updates but not background notifications

---

## Biometric Authentication

### Decision: local_auth package

**Rationale**:
- Official Flutter plugin maintained by Google, supporting both iOS (Touch ID, Face ID) and Android (Fingerprint, Face Unlock)
- Simple API: canCheckBiometrics(), authenticate() with customizable prompts in Arabic/English
- Meets FR-002 requirement: Optional quick-unlock after initial password login
- Security model: Biometric auth unlocks access to stored JWT token, password still required on first login or full session expiration

**Alternatives Considered**:
- flutter_biometric: Rejected as less maintained, local_auth is official plugin
- Platform channels (custom native code): Rejected as reinventing the wheel; local_auth handles platform quirks

**Implementation Flow**:
1. User logs in with password → JWT token stored in flutter_secure_storage
2. User enables biometric in settings → preference saved to shared_preferences
3. On subsequent app opens (session not expired): biometric prompt → on success, retrieve token from secure storage → auto-login
4. On session expiration: Prompt for password, not biometric (security best practice)

---

## Internationalization (i18n) & Localization (l10n)

### Decision: flutter_localizations with ARB (Application Resource Bundle) files

**Rationale**:
- Official Flutter i18n solution with Material Design widgets pre-localized (date pickers, dialogs)
- ARB file format (JSON-based) enables separation of UI code from translatable strings, supporting FR-004 bilingual requirement
- Strong support for RTL languages (Arabic) via Directionality widget and TextDirection configuration
- Locale-aware formatting (date/time/numbers) meets FR-026 requirement
- Dart code generation (flutter gen-l10n) provides type-safe access to translations, catching missing translations at compile time

**ARB File Structure**:
- lib/core/localization/l10n/app_en.arb: English strings (LTR baseline)
- lib/core/localization/l10n/app_ar.arb: Arabic strings (RTL)
- Each string includes translation and optional description for translators

**RTL Implementation**:
- MaterialApp configured with supported locales: [Locale('en'), Locale('ar')]
- Directionality widget automatically applied when locale is 'ar'
- Layout widgets (Row, Column, Padding) automatically reverse for RTL
- Custom layouts tested in both directions to prevent FR-004 violation (no layout breaks/text overflow)

**Language Switching**:
- User selects language in language_select_screen (first launch) or settings_screen
- Preference saved to shared_preferences
- App rebuilds MaterialApp with new locale, meeting SC-007 requirement (< 1s switch)

**Alternatives Considered**:
- easy_localization: Rejected as third-party package when official solution meets all requirements
- Manual String maps: Rejected due to lack of compile-time safety and RTL layout handling

---

## Testing Strategy

### Decision: flutter_test (unit/widget), integration_test (E2E), mockito (mocking)

**Rationale**:
- flutter_test is built-in, zero configuration for unit and widget tests (testing business logic and UI components in isolation)
- integration_test (official Flutter integration testing package) enables end-to-end flows simulating user interactions across screens
- mockito provides test doubles for API client, repositories, storage services, enabling fast, offline unit tests
- Meets constitution requirement IV (Testable Vertical Slices): Each user story tested independently with mocked dependencies

**Test Coverage Goals**:
- Unit tests: BLoCs (state transitions, event handling), repositories (API calls, data mapping), sync service (queue processing, conflict detection)
- Widget tests: Individual screens render correctly in Arabic/RTL and English/LTR, error states display properly, loading indicators appear
- Integration tests: End-to-end user journeys (US-001 login flow, US-002 case search and view, US-003 hearing calendar)

**Alternatives Considered**:
- mocktail: Rejected as mockito more mature with better documentation
- patrol: Rejected as overkill for this app's testing needs; integration_test sufficient

---

## Performance Optimization Strategies

### Background Task Handling

**Decision**: Use flutter_background_service for offline sync and flutter_local_notifications for sync completion alerts

**Rationale**:
- Offline edits must sync when network restores, even if app in background (FR-014)
- Background service processes sync queue, retrying failed operations
- Local notification alerts user when sync completes or conflicts require resolution

### Caching & Pagination

**Decision**: Implement pagination in repositories (page size: 20-50 items per FR-020), cache API responses in sqflite with timestamp-based staleness

**Rationale**:
- Large case/customer lists (1000+ items) cause memory pressure and slow rendering
- Paginated loading meets SC-002 (case search < 2s for 1000 cases) by only loading visible items
- Cache staleness mechanism: Display cached data immediately (offline or slow network), refresh in background if data > 5 minutes old

### Memory Management

**Decision**: Image caching with flutter_cache_manager, dispose of blocs on screen exit, lazy-load document content

**Rationale**:
- SC-009 requires < 150MB memory usage during normal operation
- Customer/employee profile photos cached with LRU eviction
- Document files (PDFs, images) fetched on-demand, not preloaded
- BLoCs disposed when leaving screens to prevent memory leaks

---

## Security Considerations

### Token Storage & Transmission

- JWT access tokens (short-lived, 1 hour) and refresh tokens (7 days per clarification) stored in flutter_secure_storage (encrypted keychain/keystore)
- All API calls over HTTPS (TLS 1.2+) to prevent token interception
- Tokens cleared on logout (FR-024) and when user switches tenants

### Biometric Security

- Biometric auth unlocks token, doesn't replace it (password required on first login or session expiration per FR-002 clarification)
- Failed biometric attempts fall back to password entry after 3 tries (iOS/Android default)

### Offline Data Protection

- SQLite database not encrypted by default (device encryption provides at-rest protection)
- Future enhancement: sqlcipher for database-level encryption if required by compliance audit

---

## Dependency Summary

**Core Dependencies** (pubspec.yaml):
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.0
  
  # Networking
  dio: ^5.4.0
  
  # Storage
  sqflite: ^2.3.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # Push Notifications
  firebase_messaging: ^14.7.0
  firebase_core: ^2.24.0
  
  # Authentication
  local_auth: ^2.1.0
  
  # Localization
  intl: ^0.18.0
  
  # Utilities
  flutter_cache_manager: ^3.3.0
  path_provider: ^2.1.0
  url_launcher: ^6.2.0  # For dialing phone numbers (FR-012)

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0  # Code generation for mockito
  flutter_lints: ^3.0.0
```

---

## Risk Assessment

### High Risk
- **Conflict resolution UX complexity**: Side-by-side field comparison UI must be intuitive. Mitigation: User testing with Arabic and English prototypes.
- **Offline sync edge cases**: Network interruptions during sync could corrupt queue. Mitigation: Transactional queue processing, rollback on failure.

### Medium Risk
- **Push notification delivery reliability**: FCM/APNs occasionally delay. Mitigation: In-app notification polling as fallback (check for new notifications on app open).
- **RTL layout consistency**: Third-party widgets may not fully support RTL. Mitigation: Wrap with Directionality widget, test all screens in Arabic.

### Low Risk
- **Biometric auth platform differences**: iOS Face ID vs Android Face Unlock have different UX. Mitigation: local_auth abstracts differences; test on both platforms.

---

## Open Questions & Future Research

None. All clarifications resolved in specification session 2026-03-20.

---

**End of Research Documentation**
