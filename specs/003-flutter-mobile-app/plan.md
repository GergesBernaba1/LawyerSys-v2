# Implementation Plan: Flutter Mobile App

**Branch**: `003-flutter-mobile-app` | **Date**: March 21, 2026 | **Spec**: `/specs/003-flutter-mobile-app/spec.md`
**Input**: Feature specification from `/specs/003-flutter-mobile-app/spec.md`

## Summary

Create a Flutter mobile app for LawyerSys that connects to the existing ASP.NET Core API, providing mobile access to case management, hearings, customers, and billing with offline support, bilingual UI (Arabic RTL/English LTR), and JWT authentication. The app serves multiple law firms (multi-tenant) with staff roles (lawyers, paralegals, administrators).

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x  
**Primary Dependencies**: flutter_bloc (^8.1.3), dio (^5.3.0), sqflite (^2.2.7), flutter_secure_storage (^8.0.0), firebase_messaging (^14.6.6), local_auth (^2.2.1), intl (^0.18.1), shared_preferences (^2.2.0), path_provider (^2.0.17), url_launcher (^6.1.10), connectivity_plus (^4.1.0), table_calendar (^3.0.8), flutter_pdfview (^1.2.3), photo_view (^0.14.0), flutter_cache_manager (^3.3.1), firebase_crashlytics  
**Storage**: SQLite (sqflite) for offline caching, flutter_secure_storage for JWT tokens  
**Testing**: flutter test, flutter analyze  
**Target Platform**: iOS 13+, Android 8.0+  
**Project Type**: mobile-app (Flutter iOS/Android)  
**Performance Goals**: Login <10s, case search <2s, language switch <1s, PDF <5s, memory <150MB, battery <5%/hr  
**Constraints**: Offline-capable (100MB default cache, configurable 50-500MB), RTL/LTR support, tenant isolation required, biometric authentication optional, rate limiting 60 req/min with exponential backoff  
**Scale/Scope**: 80+ screens across 25+ feature modules, multi-tenant with staff roles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Tenant Isolation Is Mandatory | ✅ PASS | Mobile app sends tenant context via TenantInterceptor in API client |
| II. Secure And Auditable Access By Default | ✅ PASS | JWT Bearer auth via AuthInterceptor, secure token storage, session expiry handling |
| III. Parity-Preserving Migration | ✅ PASS | Uses same ASP.NET Core API endpoints as web ClientApp |
| IV. Testable Vertical Slices | ✅ PASS | flutter test available; bloc pattern enables unit testing |
| V. Bilingual Operator UX | ✅ PASS | flutter_localizations with Arabic/English ARB files, RTL/LTR support implemented |

**Authorization Impact**: Mobile app respects backend role/permissions - features hidden/disabled based on user permissions (FR-021)

**Localization Impact**: Complete Arabic RTL and English LTR support required for all UI elements

**Observability**: Firebase Crashlytics + custom event logging for key flows (login, case access, hearing views)

## Project Structure

### Documentation (this feature)

```text
specs/003-flutter-mobile-app/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
MobileApp/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # App routing and theming
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart       # Dio HTTP client with rate limiting
│   │   │   ├── api_constants.dart    # API endpoints
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       └── tenant_interceptor.dart
│   │   ├── auth/
│   │   │   └── biometric_auth.dart
│   │   ├── localization/
│   │   │   ├── app_localizations.dart
│   │   │   └── l10n/
│   │   │       ├── app_en.arb
│   │   │       └── app_ar.arb
│   │   ├── storage/
│   │   │   ├── local_database.dart   # SQLite offline cache
│   │   │   ├── secure_storage.dart   # JWT tokens
│   │   │   └── preferences_storage.dart
│   │   ├── sync/
│   │   │   ├── sync_service.dart
│   │   │   ├── conflict_resolver.dart
│   │   │   └── sync_queue_item.dart
│   │   └── notifications/
│   │       ├── push_notification_service.dart
│   │       └── notification_handler.dart
│   ├── features/
│   │   ├── authentication/
│   │   ├── dashboard/
│   │   ├── cases/
│   │   ├── customers/
│   │   ├── hearings/
│   │   ├── billing/
│   │   ├── calendar/
│   │   ├── tasks/
│   │   ├── timetracking/
│   │   ├── settings/
│   │   ├── employees/
│   │   ├── courts/
│   │   ├── contenders/
│   │   ├── consultations/
│   │   ├── trust-accounting/
│   │   ├── client-portal/
│   │   ├── governments/
│   │   ├── case-relations/
│   │   ├── judicial/
│   │   ├── reports/
│   │   ├── intake/
│   │   └── notifications/
│   └── shared/
│       ├── widgets/
│       └── utils/
├── pubspec.yaml
└── flutter_test/
```

**Structure Decision**: Feature-based module structure following Flutter BLoC pattern. Core services for API, storage, localization, sync, and notifications. Feature modules contain models, repositories, blocs, and screens. Subset of web features - no client portal, document generation, e-sign, or admin panels.

---

## Phase 0: Research Tasks

All clarifications have been resolved in the spec:
- Multi-tenant architecture with staff roles ✅
- 99.5% uptime SLA ✅
- Subset feature approach (no web-only features) ✅
- Rate limiting: 60 req/min with exponential backoff ✅
- Observability: Firebase Crashlytics + event logging ✅
- Offline cache: 100MB configurable ✅
- Session: 7 days with refresh token ✅
- Push: FCM + APNs ✅
- Biometric: Optional quick-unlock ✅
- Conflict resolution: Side-by-side field comparison ✅

No additional research needed - all unknowns resolved.

---

## Phase 1: Design Artifacts

**Prerequisites**: Phase 0 complete (all clarifications resolved)

### Deliverables

1. **data-model.md**: Entity definitions matching backend API DTOs (already exists)
2. **contracts/**: API contract documentation for mobile endpoints (already exists)
3. **quickstart.md**: Development setup guide for MobileApp contributors (already exists)
4. **Agent context update**: Run update-agent-context.ps1 for Kilo agent

---

## Quality Gates

Before merge, MobileApp MUST pass:
- `flutter analyze` - No lint errors
- `flutter test` - All unit tests pass
- Build verification for iOS simulator and Android emulator
- Firebase Crashlytics integration for production builds

---

## Gap Analysis Features (Future Phases)

The spec includes 24 additional features for full ClientApp parity. These are marked as web-only features in the spec but tasks exist for implementation:

| Phase | Feature | Priority |
|-------|---------|----------|
| 1A | Employees | P1 |
| 1B | Courts | P2 |
| 1C | Contenders | P2 |
| 1D | Consultations | P2 |
| 1E | Trust Accounting | P2 |
| 1F | Client Portal | P2 |
| 1G-1K | Governments, Case Relations, Judicial, Reports, Intake | P3 |

These will be implemented after core MVP features are complete.
