# Tasks: Flutter Mobile App

**Input**: Design documents from `/specs/003-flutter-mobile-app/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are not explicitly requested in the feature specification, so test tasks are excluded.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Mobile app structure: `MobileApp/lib/` for all Dart source files

---

## Phase 0: Gap Analysis Implementation (NEW)

**Purpose**: Implement missing features from ClientApp gap analysis

### Phase 1A: Employees Management (Priority: P1)

- [x] T137 [P] Create Employee model in MobileApp/lib/features/employees/models/employee.dart with JSON serialization
- [x] T138 [P] Create EmployeesRepository in MobileApp/lib/features/employees/repositories/employees_repository.dart
- [x] T139 [P] Create EmployeesEvent classes in MobileApp/lib/features/employees/bloc/employees_event.dart
- [x] T140 [P] Create EmployeesState classes in MobileApp/lib/features/employees/bloc/employees_state.dart
- [x] T141 Create EmployeesBloc in MobileApp/lib/features/employees/bloc/employees_bloc.dart
- [x] T142 Create EmployeesListScreen in MobileApp/lib/features/employees/screens/employees_list_screen.dart
- [x] T143 Create EmployeeDetailScreen in MobileApp/lib/features/employees/screens/employee_detail_screen.dart

### Phase 1B: Courts Management (Priority: P2)

- [x] T144 [P] Create Court model in MobileApp/lib/features/courts/models/court.dart with JSON serialization
- [x] T145 [P] Create CourtsRepository in MobileApp/lib/features/courts/repositories/courts_repository.dart
- [x] T146 [P] Create CourtsEvent classes in MobileApp/lib/features/courts/bloc/courts_event.dart
- [x] T147 [P] Create CourtsState classes in MobileApp/lib/features/courts/bloc/courts_state.dart
- [x] T148 Create CourtsBloc in MobileApp/lib/features/courts/bloc/courts_bloc.dart
- [x] T149 Create CourtsListScreen in MobileApp/lib/features/courts/screens/courts_list_screen.dart
- [x] T150 Create CourtDetailScreen in MobileApp/lib/features/courts/screens/court_detail_screen.dart

### Phase 1C: Contenders Management (Priority: P2)

- [x] T151 [P] Create Contender model in MobileApp/lib/features/contenders/models/contender.dart with JSON serialization
- [x] T152 [P] Create ContendersRepository in MobileApp/lib/features/contenders/repositories/contenders_repository.dart
- [x] T153 [P] Create ContendersEvent classes in MobileApp/lib/features/contenders/bloc/contenders_event.dart
- [x] T154 [P] Create ContendersState classes in MobileApp/lib/features/contenders/bloc/contenders_state.dart
- [x] T155 Create ContendersBloc in MobileApp/lib/features/contenders/bloc/contenders_bloc.dart
- [x] T156 Create ContendersListScreen in MobileApp/lib/features/contenders/screens/contenders_list_screen.dart
- [x] T157 Create ContenderDetailScreen in MobileApp/lib/features/contenders/screens/contender_detail_screen.dart
- [x] T158 Create ContenderFormScreen in MobileApp/lib/features/contenders/screens/contender_form_screen.dart

### Phase 1D: Consultations Management (Priority: P2)

- [x] T159 [P] Create Consultation model in MobileApp/lib/features/consultations/models/consultation.dart with JSON serialization
- [x] T160 [P] Create ConsultationsRepository in MobileApp/lib/features/consultations/repositories/consultations_repository.dart
- [x] T161 [P] Create ConsultationsEvent classes in MobileApp/lib/features/consultations/bloc/consultations_event.dart
- [x] T162 [P] Create ConsultationsState classes in MobileApp/lib/features/consultations/bloc/consultations_state.dart
- [x] T163 Create ConsultationsBloc in MobileApp/lib/features/consultations/bloc/consultations_bloc.dart
- [x] T164 Create ConsultationsListScreen in MobileApp/lib/features/consultations/screens/consultations_list_screen.dart
- [x] T165 Create ConsultationDetailScreen in MobileApp/lib/features/consultations/screens/consultation_detail_screen.dart

### Phase 1E: Trust Accounting (Priority: P2)

- [x] T166 [P] Create TrustTransaction model in MobileApp/lib/features/trust-accounting/models/trust_transaction.dart with JSON serialization
- [x] T167 [P] Create TrustAccountingRepository in MobileApp/lib/features/trust-accounting/repositories/trust_accounting_repository.dart
- [x] T168 [P] Create TrustAccountingEvent classes in MobileApp/lib/features/trust-accounting/bloc/trust_accounting_event.dart
- [x] T169 [P] Create TrustAccountingState classes in MobileApp/lib/features/trust-accounting/bloc/trust_accounting_state.dart
- [x] T170 Create TrustAccountingBloc in MobileApp/lib/features/trust-accounting/bloc/trust_accounting_bloc.dart
- [x] T171 Create TrustAccountingListScreen in MobileApp/lib/features/trust-accounting/screens/trust_list_screen.dart
- [x] T172 Create TrustFormScreen in MobileApp/lib/features/trust-accounting/screens/trust_form_screen.dart

### Phase 1F: Client Portal (Priority: P2)

- [x] T173 [P] Create PortalMessage model in MobileApp/lib/features/client-portal/models/portal_message.dart with JSON serialization
- [x] T174 [P] Create ClientPortalRepository in MobileApp/lib/features/client-portal/repositories/client_portal_repository.dart
- [x] T175 [P] Create ClientPortalEvent classes in MobileApp/lib/features/client-portal/bloc/client_portal_event.dart
- [x] T176 [P] Create ClientPortalState classes in MobileApp/lib/features/client-portal/bloc/client_portal_state.dart
- [x] T177 Create ClientPortalBloc in MobileApp/lib/features/client-portal/bloc/client_portal_bloc.dart
- [x] T178 Create PortalMessagesScreen in MobileApp/lib/features/client-portal/screens/portal_messages_screen.dart
- [x] T179 Create PortalDocumentsScreen in MobileApp/lib/features/client-portal/screens/portal_documents_screen.dart

### Phase 1G: Governments (Priority: P3)

- [x] T180 [P] Create Government model in MobileApp/lib/features/governments/models/government.dart with JSON serialization
- [x] T181 [P] Create GovernmentsRepository in MobileApp/lib/features/governments/repositories/governments_repository.dart
- [x] T182 Create GovernmentsBloc in MobileApp/lib/features/governments/bloc/governments_bloc.dart
- [x] T183 Create GovernmentsListScreen in MobileApp/lib/features/governments/screens/governments_list_screen.dart

### Phase 1H: Case Relations (Priority: P3)

- [x] T184 [P] Create CaseRelation model in MobileApp/lib/features/case-relations/models/case_relation.dart with JSON serialization
- [x] T185 [P] Create CaseRelationsRepository in MobileApp/lib/features/case-relations/repositories/case_relations_repository.dart
- [x] T186 Create CaseRelationsBloc in MobileApp/lib/features/case-relations/bloc/case_relations_bloc.dart
- [x] T187 Create CaseRelationsListScreen in MobileApp/lib/features/case-relations/screens/case_relations_list_screen.dart

### Phase 1I: Judicial Documents (Priority: P3)

- [x] T188 [P] Create JudicialDocument model in MobileApp/lib/features/judicial/models/judicial_document.dart with JSON serialization
- [x] T189 [P] Create JudicialDocumentsRepository in MobileApp/lib/features/judicial/repositories/judicial_documents_repository.dart
- [x] T190 Create JudicialDocumentsBloc in MobileApp/lib/features/judicial/bloc/judicial_documents_bloc.dart
- [x] T191 Create JudicialDocumentsListScreen in MobileApp/lib/features/judicial/screens/judicial_documents_list_screen.dart

### Phase 1J: Reports (Priority: P3)

- [x] T192 [P] Create Report model in MobileApp/lib/features/reports/models/report.dart with JSON serialization
- [x] T193 [P] Create ReportsRepository in MobileApp/lib/features/reports/repositories/reports_repository.dart
- [x] T194 Create ReportsBloc in MobileApp/lib/features/reports/bloc/reports_bloc.dart
- [x] T195 Create ReportsScreen in MobileApp/lib/features/reports/screens/reports_screen.dart

### Phase 1K: Intake Forms (Priority: P3)

- [x] T196 [P] Create IntakeForm model in MobileApp/lib/features/intake/models/intake_form.dart with JSON serialization
- [x] T197 [P] Create IntakeRepository in MobileApp/lib/features/intake/repositories/intake_repository.dart
- [x] T198 Create IntakeBloc in MobileApp/lib/features/intake/bloc/intake_bloc.dart
- [x] T199 Create IntakeFormScreen in MobileApp/lib/features/intake/screens/intake_form_screen.dart

### Phase 1L: Billing (Priority: P2 - Already exists in MobileApp)

- [x] T200 [P] [EXISTS] Billing module already implemented in MobileApp

### Phase 1M: Time Tracking (Priority: P2 - Already exists in MobileApp)

- [x] T201 [P] [EXISTS] Time Tracking module already implemented in MobileApp

### Phase 1N: Tasks (Priority: P2 - Already exists in MobileApp)

- [x] T202 [P] [EXISTS] Tasks module already implemented in MobileApp

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create Flutter project in MobileApp/ directory with `flutter create --org com.lawyersys --platforms android,ios MobileApp`
- [x] T002 Configure pubspec.yaml with all dependencies (flutter_bloc, dio, sqflite, flutter_secure_storage, firebase_messaging, local_auth, flutter_localizations, intl, shared_preferences, path_provider, url_launcher)
- [x] T003 [P] Create project directory structure in MobileApp/lib/ (core/, features/, shared/)
- [x] T004 [P] Configure Firebase project and add google-services.json to MobileApp/android/app/
- [x] T005 [P] Configure Firebase project and add GoogleService-Info.plist to MobileApp/ios/Runner/
- [x] T006 [P] Create flutter_gen_l10n.yaml configuration file in MobileApp/ for localization generation
- [x] T007 [P] Configure Android SDK versions in MobileApp/android/app/build.gradle (minSdk 26 for Android 8.0+)
- [x] T008 [P] Configure iOS deployment target in MobileApp/ios/Podfile (iOS 13.0+)
- [x] T009 Run `flutter pub get` in MobileApp/ to install all dependencies

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T010 [P] Create ApiConstants class in MobileApp/lib/core/api/api_constants.dart with base URL and endpoint definitions
- [x] T011 Create ApiClient class in MobileApp/lib/core/api/api_client.dart with Dio HTTP client configuration
- [x] T012 [P] Implement AuthInterceptor in MobileApp/lib/core/api/interceptors/auth_interceptor.dart for JWT token injection
- [x] T013 [P] Implement TenantInterceptor in MobileApp/lib/core/api/interceptors/tenant_interceptor.dart for X-Tenant-Id header
- [x] T014 [P] Create SecureStorage service in MobileApp/lib/core/storage/secure_storage.dart for JWT token persistence using flutter_secure_storage
- [x] T015 [P] Create PreferencesStorage service in MobileApp/lib/core/storage/preferences_storage.dart for user settings using shared_preferences
- [x] T016 Create LocalDatabase helper in MobileApp/lib/core/storage/local_database.dart with SQLite schema initialization (cases, customers, hearings, courts, employees, documents, notifications, governorates, contenders, sync_queue, dashboard_summary tables)
- [x] T017 Create SyncQueueItem model in MobileApp/lib/core/sync/sync_queue_item.dart with JSON serialization
- [x] T018 Create SyncService class in MobileApp/lib/core/sync/sync_service.dart for offline sync queue management (stub implementation, full implementation in Phase 10)
- [x] T019 [P] Create app_localizations.dart in MobileApp/lib/core/localization/ for localization setup
- [x] T020 [P] Create app_en.arb in MobileApp/lib/core/localization/l10n/ with English translations (initial set: login, dashboard, cases keys)
- [x] T021 [P] Create app_ar.arb in MobileApp/lib/core/localization/l10n/ with Arabic translations (initial set: login, dashboard, cases keys)
- [x] T022 Run `flutter gen-l10n` to generate localization code
- [x] T023 [P] Create OfflineIndicator widget in MobileApp/lib/shared/widgets/offline_indicator.dart
- [x] T024 [P] Create LoadingIndicator widget in MobileApp/lib/shared/widgets/loading_indicator.dart
- [x] T025 [P] Create ErrorMessage widget in MobileApp/lib/shared/widgets/error_message.dart
- [x] T026 [P] Create DateFormatter utility in MobileApp/lib/shared/utils/date_formatter.dart for locale-aware date formatting
- [x] T027 [P] Create Validators utility in MobileApp/lib/shared/utils/validators.dart for email, phone, SSN validation
- [x] T028 Create main.dart in MobileApp/lib/ as app entry point with MaterialApp configuration
- [x] T029 Create app.dart in MobileApp/lib/ with MaterialApp setup including localization delegates and supported locales (en, ar)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Secure Login and Dashboard Access (Priority: P1) 🎯 MVP

**Goal**: Enable users to authenticate securely and view dashboard with workload overview (case count, upcoming hearings, recent activities)

**Independent Test**: Authenticate with valid credentials and verify dashboard displays accurate statistics. Session persists across app restarts.

### Implementation for User Story 1

- [x] T030 [P] [US1] Create UserSession model in MobileApp/lib/features/authentication/models/user_session.dart with JSON serialization (userId, email, fullName, tenantId, tenantName, accessToken, refreshToken, tokenExpiresAt, roles, permissions, languageCode, biometricEnabled fields)
- [x] T031 [P] [US1] Create LoginRequest model in MobileApp/lib/features/authentication/models/login_request.dart
- [x] T032 [P] [US1] Create DashboardSummary model in MobileApp/lib/features/dashboard/models/dashboard_summary.dart with JSON serialization (totalCasesCount, activeCasesCount, upcomingHearingsCount, pendingTasksCount, recentActivities)
- [x] T033 [P] [US1] Create RecentActivity model in MobileApp/lib/features/dashboard/models/recent_activity.dart with JSON serialization
- [x] T034 [US1] Create AuthRepository in MobileApp/lib/features/authentication/repositories/auth_repository.dart with login, logout, refreshToken, registerDeviceToken methods using ApiClient
- [x] T035 [US1] Create DashboardRepository in MobileApp/lib/features/dashboard/repositories/dashboard_repository.dart with getSummary method using ApiClient and LocalDatabase caching
- [x] T036 [P] [US1] Create AuthEvent classes in MobileApp/lib/features/authentication/bloc/auth_event.dart (LoginRequested, LogoutRequested, SessionRestored, TokenRefreshRequested)
- [x] T037 [P] [US1] Create AuthState classes in MobileApp/lib/features/authentication/bloc/auth_state.dart (AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated, AuthError)
- [x] T038 [US1] Create AuthBloc in MobileApp/lib/features/authentication/bloc/auth_bloc.dart implementing event handlers for login, logout, session restore, token refresh
- [x] T039 [P] [US1] Create DashboardEvent classes in MobileApp/lib/features/dashboard/bloc/dashboard_event.dart (LoadDashboard, RefreshDashboard)
- [x] T040 [P] [US1] Create DashboardState classes in MobileApp/lib/features/dashboard/bloc/dashboard_state.dart (DashboardInitial, DashboardLoading, DashboardLoaded, DashboardError, DashboardOffline)
- [x] T041 [US1] Create DashboardBloc in MobileApp/lib/features/dashboard/bloc/dashboard_bloc.dart implementing event handlers for loading and refreshing dashboard
- [x] T042 [US1] Create LanguageSelectScreen in MobileApp/lib/features/authentication/screens/language_select_screen.dart with Arabic/English selection UI
- [x] T043 [US1] Create LoginScreen in MobileApp/lib/features/authentication/screens/login_screen.dart with email and password fields, login button, and error display
- [x] T043b [US1] Implement role/permission UI gating and route guards for FR-021 (main tabs, cases create/edit/delete, billing create/delete, navigation routes) in MobileApp/lib/**
- [x] T044 [US1] Create DashboardScreen in MobileApp/lib/features/dashboard/screens/dashboard_screen.dart with statistics display, recent activities list, navigation to cases/hearings/customers, and pull-to-refresh
- [x] T045 [US1] Implement BiometricAuthService in MobileApp/lib/core/auth/biometric_auth.dart using local_auth package for optional quick-unlock
- [x] T046 [US1] Update AuthBloc to support biometric authentication flow (unlock stored token on biometric success)
- [x] T047 [US1] Update main.dart to check for stored session on app startup and navigate to Dashboard or LanguageSelect/Login accordingly

### Phase 3B: Tests for User Story 1 - Login and Dashboard (Priority: P1)

- [x] T048 [P] Create AuthBloc tests in MobileApp/flutter_test/features/authentication/bloc/auth_bloc_test.dart covering login, logout, session restore, token refresh, biometric unlock, and error states
- [x] T049 [P] Create DashboardBloc tests in MobileApp/flutter_test/features/dashboard/bloc/dashboard_bloc_test.dart covering load, refresh, and offline states
- [x] T050 [P] Create AuthRepository tests in MobileApp/flutter_test/features/authentication/repositories/auth_repository_test.dart mocking ApiClient
- [x] T051 [P] Create DashboardRepository tests in MobileApp/flutter_test/features/dashboard/repositories/dashboard_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T052 Create integration test for login and dashboard flow in MobileApp/integration_test/auth_dashboard_flow_test.dart

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 6 - Bilingual Interface Support (Priority: P1) 🎯 MVP

**Goal**: Enable users to switch between Arabic (RTL) and English (LTR) with complete UI adaptation

**Independent Test**: Switch languages and verify all UI elements, navigation, and data display correctly in both languages with appropriate text direction

### Implementation for User Story 6

- [x] T053 [P] [US6] Expand app_en.arb in MobileApp/lib/core/localization/l10n/ with complete English translations for all screens (cases, hearings, customers, documents, settings, error messages, validation messages)
- [x] T054 [P] [US6] Expand app_ar.arb in MobileApp/lib/core/localization/l10n/ with complete Arabic translations for all screens
- [x] T055 [US6] Run `flutter gen-l10n` to regenerate localization code with all translations
- [x] T056 [US6] Create SettingsScreen in MobileApp/lib/features/settings/screens/settings_screen.dart with language selection, notification preferences toggle, offline cache size configuration, app version display
- [x] T057 [US6] Update app.dart to use localeResolutionCallback and wrap MaterialApp with builder that applies Directionality widget based on locale
- [x] T058 [US6] Update PreferencesStorage to persist language selection (languageCode)
- [x] T059 [US6] Update all screens to use AppLocalizations.of(context) for all UI text instead of hardcoded strings
- [x] T060 [US6] Test RTL layout on all implemented screens (LanguageSelect, Login, Dashboard) with Arabic locale and verify navigation, text alignment, layout mirroring are correct

**Checkpoint**: At this point, User Stories 1 AND 6 should both work independently - MVP baseline complete (login with bilingual support)

---

## Phase 5: User Story 2 - Case Management and Search (Priority: P1) 🎯 MVP

**Goal**: Enable users to search, view, and update case information including case details, customers, court info, and status

**Independent Test**: Search for cases, view case details, update case information. Offline mode displays cached cases with indicator.

### Implementation for User Story 2

- [x] T061 [P] [US2] Create Case model in MobileApp/lib/features/cases/models/case.dart with JSON serialization (caseId, tenantId, caseNumber, invitationType, caseStatus, caseType, filingDate, closingDate, customerId, customerFullName, courtId, courtName, assignedEmployees, lastSyncedAt, isDirty fields)
- [x] T062 [P] [US2] Create EmployeeAssignment model in MobileApp/lib/features/cases/models/employee_assignment.dart with JSON serialization
- [x] T063 [US2] Create CasesRepository in MobileApp/lib/features/cases/repositories/cases_repository.dart with getCases, getCaseById, updateCase, searchCases methods using ApiClient and LocalDatabase caching with pagination support
- [x] T064 [P] [US2] Create CasesEvent classes in MobileApp/lib/features/cases/bloc/cases_event.dart (LoadCases, SearchCases, LoadMoreCases, RefreshCases, SelectCase, UpdateCase)
- [x] T065 [P] [US2] Create CasesState classes in MobileApp/lib/features/cases/bloc/cases_state.dart (CasesInitial, CasesLoading, CasesLoaded, CasesError, CasesOffline, CaseDetailLoaded)
- [x] T066 [US2] Create CasesBloc in MobileApp/lib/features/cases/bloc/cases_bloc.dart implementing event handlers for loading, searching, pagination, refreshing, and updating cases
- [x] T067 [US2] Create CasesListScreen in MobileApp/lib/features/cases/screens/cases_list_screen.dart with search bar, filterable/sortable list, pagination (load more on scroll), pull-to-refresh, offline indicator
- [x] T068 [US2] Create CaseDetailScreen in MobileApp/lib/features/cases/screens/case_detail_screen.dart with complete case information display (customer, court, employees, status, dates), edit button for users with EditCases permission, tabs for hearings and documents
- [x] T069 [US2] Implement case update functionality in CasesBloc with conflict detection (check X-Last-Modified header in API call, handle 409 Conflict response)
- [x] T070 [US2] Update DashboardScreen to add navigation to CasesListScreen when tapping case count card
- [x] T071 [US2] Update LocalDatabase to implement case caching (insert/update cases table with tenant isolation, query with pagination, mark isDirty for offline edits)
- [x] T072 [US2] Update SyncService to add cases to sync queue when edited offline (insert SyncQueueItem with operationType='UPDATE')

### Phase 5B: Tests for User Story 2 - Case Management (Priority: P1)

- [x] T073 [P] Create CasesBloc tests in MobileApp/flutter_test/features/cases/bloc/cases_bloc_test.dart covering load, search, pagination, update, conflict detection, and offline states
- [x] T074 [P] Create CasesRepository tests in MobileApp/flutter_test/features/cases/repositories/cases_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T075 [P] Create widget tests for CasesListScreen in MobileApp/flutter_test/features/cases/screens/cases_list_screen_test.dart covering search, pagination, pull-to-refresh
- [x] T076 [P] Create widget tests for CaseDetailScreen in MobileApp/flutter_test/features/cases/screens/case_detail_screen_test.dart covering display, edit mode, tabs
- [x] T077 Create integration test for case management flow in MobileApp/integration_test/cases_flow_test.dart

**Checkpoint**: At this point, User Stories 1, 2, AND 6 should all work independently - Core MVP complete

---

## Phase 6: User Story 3 - Hearing Schedule and Calendar View (Priority: P2)

**Goal**: Enable users to view upcoming court hearings in list and calendar views with hearing details

**Independent Test**: View hearings list, switch to calendar view, filter by date range, view hearing details

### Implementation for User Story 3

- [x] T073 [P] [US3] Create Hearing model in MobileApp/lib/features/hearings/models/hearing.dart with JSON serialization (hearingId, tenantId, hearingDate, hearingTime, caseId, caseNumber, judgeName, courtId, courtName, courtLocation, hearingNotificationDetails, notes, lastSyncedAt, isDirty fields)
- [x] T074 [US3] Create HearingsRepository in MobileApp/lib/features/hearings/repositories/hearings_repository.dart with getHearings, getHearingById, createHearing, updateHearing methods using ApiClient and LocalDatabase caching with date range filtering
- [x] T075 [P] [US3] Create HearingsEvent classes in MobileApp/lib/features/hearings/bloc/hearings_event.dart (LoadHearings, FilterHearingsByDate, SelectHearing, CreateHearing, UpdateHearing, RefreshHearings)
- [x] T076 [P] [US3] Create HearingsState classes in MobileApp/lib/features/hearings/bloc/hearings_state.dart (HearingsInitial, HearingsLoading, HearingsLoaded, HearingsError, HearingsOffline, HearingDetailLoaded)
- [x] T077 [US3] Create HearingsBloc in MobileApp/lib/features/hearings/bloc/hearings_bloc.dart implementing event handlers for loading, filtering, selecting, creating, updating hearings
- [x] T078 [US3] Create HearingsListScreen in MobileApp/lib/features/hearings/screens/hearings_list_screen.dart with list view showing upcoming hearings sorted by date, filter by date range, pull-to-refresh, offline indicator
- [x] T079 [US3] Create HearingsCalendarScreen in MobileApp/lib/features/hearings/screens/hearings_calendar_screen.dart with monthly calendar view (use table_calendar package), visual indicators for hearing dates, tap date to show day's hearings, navigation controls
- [x] T080 [US3] Update HearingsListScreen to add toggle button switching between list and calendar views
- [x] T081 [US3] Update DashboardScreen to add navigation to HearingsListScreen when tapping upcoming hearings count card
- [x] T082 [US3] Update LocalDatabase to implement hearing caching (insert/update hearings table with tenant isolation, query by date range)
- [x] T083 [US3] Update SyncService to add hearings to sync queue when created/edited offline
- [x] T084 [US3] Add table_calendar dependency to pubspec.yaml and run `flutter pub get`

### Phase 6B: Tests for User Story 3 - Hearing Schedule (Priority: P2)

- [x] T085 [P] Create HearingsBloc tests in MobileApp/flutter_test/features/hearings/bloc/hearings_bloc_test.dart covering load, filter, select, create, update, and offline states
- [x] T086 [P] Create HearingsRepository tests in MobileApp/flutter_test/features/hearings/repositories/hearings_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T087 [P] Create widget tests for HearingsListScreen in MobileApp/flutter_test/features/hearings/screens/hearings_list_screen_test.dart covering list view, filtering, toggle
- [x] T088 [P] Create widget tests for HearingsCalendarScreen in MobileApp/flutter_test/features/hearings/screens/hearings_calendar_screen_test.dart covering calendar view, date selection
- [x] T089 Create integration test for hearings flow in MobileApp/integration_test/hearings_flow_test.dart

**Checkpoint**: At this point, User Stories 1, 2, 3, AND 6 should all work independently

---

## Phase 7: User Story 4 - Customer and Contact Management (Priority: P2)

**Goal**: Enable users to search customers, view customer details with case history, and initiate calls/messages from customer profiles

**Independent Test**: Search customers by name/SSN, view customer details, view customer's cases, tap phone number to open dialer

### Implementation for User Story 4

- [x] T090 [P] [US4] Create Customer model in MobileApp/lib/features/customers/models/customer.dart with JSON serialization (customerId, tenantId, fullName, ssn, birthDate, phoneNumber, mobileNumber, email, address, customerType, associatedCasesCount, lastSyncedAt, isDirty fields)
- [x] T091 [US4] Create CustomersRepository in MobileApp/lib/features/customers/repositories/customers_repository.dart with getCustomers, getCustomerById, searchCustomers methods using ApiClient and LocalDatabase caching with pagination support
- [x] T092 [P] [US4] Create CustomersEvent classes in MobileApp/lib/features/customers/bloc/customers_event.dart (LoadCustomers, SearchCustomers, LoadMoreCustomers, SelectCustomer, RefreshCustomers)
- [x] T093 [P] [US4] Create CustomersState classes in MobileApp/lib/features/customers/bloc/customers_state.dart (CustomersInitial, CustomersLoading, CustomersLoaded, CustomersError, CustomersOffline, CustomerDetailLoaded)
- [x] T094 [US4] Create CustomersBloc in MobileApp/lib/features/customers/bloc/customers_bloc.dart implementing event handlers for loading, searching, pagination, selecting customers
- [x] T095 [US4] Create CustomersListScreen in MobileApp/lib/features/customers/screens/customers_list_screen.dart with search bar (name/SSN), customer list with contact info, pagination, pull-to-refresh, offline indicator
- [x] T096 [US4] Create CustomerDetailScreen in MobileApp/lib/features/customers/screens/customer_detail_screen.dart with customer information display, tabs for contact details and associated cases, clickable phone number (launches dialer via url_launcher), clickable email (launches mail app)
- [x] T097 [US4] Implement device integration in CustomerDetailScreen using url_launcher package (tel: for phone calls, sms: for messages, mailto: for email) (FR-012)
- [x] T097.1 [US4] Implement list-level direct communication actions in CustomersListScreen using url_launcher (popup menu with call/message) (FR-012)
- [x] T098 [US4] Update DashboardScreen to add navigation drawer or bottom navigation including Customers option
- [x] T099 [US4] Update LocalDatabase to implement customer caching (insert/update customers table with tenant isolation, search by name/SSN)

### Phase 7B: Tests for User Story 4 - Customer Management (Priority: P2)

- [x] T100 [P] Create CustomersBloc tests in MobileApp/flutter_test/features/customers/bloc/customers_bloc_test.dart covering load, search, pagination, and offline states
- [x] T101 [P] Create CustomersRepository tests in MobileApp/flutter_test/features/customers/repositories/customers_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T102 [P] Create widget tests for CustomersListScreen in MobileApp/flutter_test/features/customers/screens/customers_list_screen_test.dart covering search, pagination
- [x] T103 [P] Create widget tests for CustomerDetailScreen in MobileApp/flutter_test/features/customers/screens/customer_detail_screen_test.dart covering display, tabs, device integration
- [x] T104 Create integration test for customer management flow in MobileApp/integration_test/customers_flow_test.dart

**Checkpoint**: At this point, User Stories 1, 2, 3, 4, AND 6 should all work independently

---

## Phase 8: User Story 5 - Notifications and Real-time Updates (Priority: P3)

**Goal**: Enable users to receive push notifications for important events (case assignments, hearing reminders, task alerts) and view notification history

**Independent Test**: Trigger notification event (backend or Firebase console), verify notification received, tap notification to navigate to relevant screen

### Implementation for User Story 5

- [x] T105 [P] [US5] Create Notification model in MobileApp/lib/features/notifications/models/notification.dart with JSON serialization (notificationId, tenantId, userId, notificationType, title, message, relatedEntityType, relatedEntityId, createdAt, isRead fields)
- [x] T106 [P] [US5] Create PushNotificationService in MobileApp/lib/core/notifications/push_notification_service.dart with Firebase messaging initialization, device token retrieval, foreground/background notification handlers
- [x] T107 [P] [US5] Create NotificationHandler in MobileApp/lib/core/notifications/notification_handler.dart with notification tap routing logic (navigate to case/hearing/customer based on relatedEntityType)
- [x] T108 [US5] Update AuthRepository to call registerDeviceToken API endpoint after successful login with FCM device token
- [x] T109 [US5] Initialize Firebase messaging in main.dart, request notification permissions (iOS), setup notification handlers
- [x] T110 [US5] Create NotificationsRepository in MobileApp/lib/features/notifications/repositories/notifications_repository.dart with getNotifications, markAsRead methods using ApiClient and LocalDatabase caching
- [x] T111 [P] [US5] Create NotificationsEvent classes in MobileApp/lib/features/notifications/bloc/notifications_event.dart (LoadNotifications, MarkAsRead, RefreshNotifications)
- [x] T112 [P] [US5] Create NotificationsState classes in MobileApp/lib/features/notifications/bloc/notifications_state.dart (NotificationsInitial, NotificationsLoading, NotificationsLoaded, NotificationsError)
- [x] T113 [US5] Create NotificationsBloc in MobileApp/lib/features/notifications/bloc/notifications_bloc.dart implementing event handlers for loading and marking notifications as read
- [x] T114 [US5] Create NotificationsScreen in MobileApp/lib/features/notifications/screens/notifications_screen.dart with notification list grouped by type, sorted by recency, tap to view details and mark as read
- [x] T115 [US5] Update DashboardScreen to add notification icon in app bar with unread count badge
- [x] T116 [US5] Update LocalDatabase to implement notification caching (insert/update notifications table, query by user and tenant, filter unread)
- [x] T117 [US5] Configure Android notification channels in MobileApp/android/app/src/main/AndroidManifest.xml for different notification types
- [x] T118 [US5] Configure iOS notification capabilities in MobileApp/ios/Runner/Info.plist and request permissions

### Phase 8B: Tests for User Story 5 - Notifications (Priority: P3)

- [x] T119 [P] Create NotificationsBloc tests in MobileApp/flutter_test/features/notifications/bloc/notifications_bloc_test.dart covering load, mark as read, and error states
- [x] T120 [P] Create NotificationsRepository tests in MobileApp/flutter_test/features/notifications/repositories/notifications_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T121 [P] Create widget tests for NotificationsScreen in MobileApp/flutter_test/features/notifications/screens/notifications_screen_test.dart covering grouping, sorting, tap actions
- [x] T122 [P] Create PushNotificationService tests in MobileApp/flutter_test/core/notifications/push_notification_service_test.dart covering initialization, token handling
- [x] T123 Create integration test for notifications flow in MobileApp/integration_test/notifications_flow_test.dart

**Checkpoint**: At this point, User Stories 1, 2, 3, 4, 5, AND 6 should all work independently

---

## Phase 9: User Story 7 - Document and File Access (Priority: P3)

**Goal**: Enable users to view case-related documents and files, view PDFs and images, download files to device

**Independent Test**: Navigate to case's files tab, view document list, open PDF in viewer, download file to device

### Implementation for User Story 7

- [x] T124 [P] [US7] Create Document model in MobileApp/lib/features/documents/models/document.dart with JSON serialization (documentId, tenantId, caseId, fileName, fileType, mimeType, fileSizeBytes, uploadDate, uploadedByUserId, uploadedByUserName, downloadUrl, localFilePath, isDownloaded fields)
- [x] T125 [US7] Create DocumentsRepository in MobileApp/lib/features/documents/repositories/documents_repository.dart with getDocumentsByCase, downloadDocument methods using ApiClient and LocalDatabase caching, flutter_cache_manager for file storage
- [x] T126 [P] [US7] Create DocumentsEvent classes in MobileApp/lib/features/documents/bloc/documents_event.dart (LoadDocuments, DownloadDocument, ViewDocument)
- [x] T127 [P] [US7] Create DocumentsState classes in MobileApp/lib/features/documents/bloc/documents_state.dart (DocumentsInitial, DocumentsLoading, DocumentsLoaded, DocumentsError, DocumentDownloading, DocumentDownloaded)
- [x] T128 [US7] Create DocumentsBloc in MobileApp/lib/features/documents/bloc/documents_bloc.dart implementing event handlers for loading documents, downloading files, tracking download progress
- [x] T129 [US7] Create DocumentViewerScreen in MobileApp/lib/features/documents/screens/document_viewer_screen.dart with PDF viewer (using flutter_pdfview or syncfusion_flutter_pdfviewer), image viewer with zoom/pan (using photo_view), download button, progress indicator
- [x] T130 [US7] Update CaseDetailScreen to add Documents tab displaying document list with file names, upload dates, file sizes, tap to open in DocumentViewerScreen
- [x] T131 [US7] Update LocalDatabase to implement document metadata caching (insert/update documents table, track local file paths for downloaded files)
- [x] T132 [US7] Add flutter_pdfview (or syncfusion_flutter_pdfviewer), photo_view, flutter_cache_manager dependencies to pubspec.yaml and run `flutter pub get`

### Phase 9B: Tests for User Story 7 - Document Access (Priority: P3)

- [x] T133 [P] Create DocumentsBloc tests in MobileApp/flutter_test/features/documents/bloc/documents_bloc_test.dart covering load, download, and error states
- [x] T134 [P] Create DocumentsRepository tests in MobileApp/flutter_test/features/documents/repositories/documents_repository_test.dart mocking ApiClient and LocalDatabase
- [x] T135 [P] Create widget tests for DocumentViewerScreen in MobileApp/flutter_test/features/documents/screens/document_viewer_screen_test.dart covering PDF/image viewing, download
- [x] T136 [P] Create integration test for document workflow in MobileApp/integration_test/documents_flow_test.dart

**Checkpoint**: All user stories (1-7) should now be independently functional

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and finalize implementation

- [x] T137 [P] Create ConflictResolverWidget in MobileApp/lib/core/sync/conflict_resolver.dart with side-by-side field comparison UI for conflict resolution (called when SyncService detects 409 Conflict response)
- [x] T138 [X] Implement full offline sync queue processing in SyncService (process sync_queue table in chronological order, send each operation to API, handle 409 conflicts by showing ConflictResolverWidget, remove from queue on success)
- [x] T139 Add network connectivity listener in SyncService (using connectivity_plus package) to auto-trigger sync when connection restored
- [x] T140 [P] Implement cache size monitoring in LocalDatabase (check total database file size, auto-evict oldest cached data if exceeds user-configured limit from SettingsScreen)
- [x] T141 [P] Add memory management for document downloads (implement LRU eviction in flutter_cache_manager for downloaded files)
- [x] T142 [P] Optimize list rendering performance with virtualization (ensure ListView.builder used everywhere, not ListView with all items)
- [x] T143 [P] Add proper BLoC disposal in all screens (BlocProvider.close) to prevent memory leaks
- [x] T144 [P] Implement API version checking in ApiClient (compare X-API-Version header response with expected version, show update prompt if mismatch per FR-022)
- [x] T145 [P] Add comprehensive error handling in all BLoCs (catch dio exceptions, sqlite exceptions, map to user-friendly error messages in selected language)
- [x] T146 [P] Implement logout functionality in SettingsScreen (clear SecureStorage tokens, clear LocalDatabase cached data, clear PreferencesStorage except language preference, navigate to LanguageSelect/Login)
- [x] T147 [P] Add Court model and reference data caching in LocalDatabase (load once on first app launch, cache for 7 days)
- [x] T148 [P] Add Governorate model and reference data caching in LocalDatabase (load once on first app launch, cache permanently)
- [x] T149 [P] Add Employee model and reference data caching in LocalDatabase (load once per day, cache in employees table)
- [x] T150 [P] Add Contender model (loaded with case details, not separately cached)
- [x] T151 [P] Implement session expiration detection in AuthInterceptor (check tokenExpiresAt before API calls, auto-refresh token if expired, prompt re-login if refresh fails)
- [x] T152 [P] Add logging throughout the app using dart:developer log function (log auth events, API calls, errors, sync operations per FR-018)
- [x] T153 Create app icon and splash screen for Android (MobileApp/android/app/src/main/res/)
- [x] T154 Create app icon and splash screen for iOS (MobileApp/ios/Runner/Assets.xcassets/)
- [x] T155 Update README.md in MobileApp/ with setup instructions, Firebase configuration steps, running instructions
- [x] T156 Run quickstart.md validation (flutter doctor, flutter test, flutter run on Android emulator, flutter run on iOS simulator)
- [x] T157 Performance profiling with Flutter DevTools (check memory usage < 150MB, frame rate 60fps, identify bottlenecks)
- [x] T158 Test complete offline workflow (go offline, view cached data, edit case, go online, trigger sync, resolve conflict)
- [x] T159 Test language switching across all screens (verify RTL layout, translations complete, no layout breaks in Arabic)
- [x] T160 Add connectivity_plus dependency to pubspec.yaml for network status monitoring and run `flutter pub get`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-9)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 10)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 - Login/Dashboard (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 6 - Bilingual (P1)**: Can start after Foundational (Phase 2) - Independent from US1 but integrates with all screens
- **User Story 2 - Cases (P1)**: Can start after Foundational (Phase 2) - Independent but integrates with Dashboard navigation
- **User Story 3 - Hearings (P2)**: Can start after Foundational (Phase 2) - Independent but integrates with Dashboard navigation
- **User Story 4 - Customers (P2)**: Can start after Foundational (Phase 2) - Independent but integrates with Dashboard navigation
- **User Story 5 - Notifications (P3)**: Can start after Foundational (Phase 2) - Independent but integrates with Dashboard app bar
- **User Story 7 - Documents (P3)**: Can start after US2 (Cases) - Documents accessed from case details, requires Case model

### Within Each User Story

- Models before repositories (repositories use models for JSON serialization)
- Repositories before BLoCs (BLoCs call repository methods)
- BLoCs before screens (screens use BlocBuilder/BlocListener with BLoCs)
- Core implementation before integration with other features

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2 constraints)
- Once Foundational phase completes, all P1 user stories can start in parallel (US1, US6, US2)
- P2 user stories (US3, US4) can start in parallel after Foundational
- P3 user stories (US5, US7) can start in parallel after Foundational (US7 should wait for US2 Case model)
- Models within a story marked [P] can run in parallel
- BLoC event/state classes marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members
- Polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# After Phase 2 completes, these tasks can all start in parallel:
T030, T031, T032, T033 (all models)
T036, T037 (AuthEvent and AuthState)
T039, T040 (DashboardEvent and DashboardState)

# Then these can run in parallel (depend on models):
T034 (AuthRepository)
T035 (DashboardRepository)

# Then these can run in parallel (depend on repositories):
T038 (AuthBloc)
T041 (DashboardBloc)

# Then these can run in parallel (depend on BLoCs):
T042 (LanguageSelectScreen)
T043 (LoginScreen)
T044 (DashboardScreen)
T045 (BiometricAuthService)

# Test tasks (depend on implementation):
T048, T049, T050, T051 (unit and widget tests)
T052 (integration test)

# Finally sequential:
T046 (Update AuthBloc with biometric)
T047 (Update main.dart routing)
```

---

## Implementation Strategy

### MVP Scope (Recommended first delivery)

Complete **Phase 1, 2, 3, 4, 5** for minimum viable product:
- ✅ Setup and infrastructure
- ✅ User Story 1: Login and Dashboard (P1)
- ✅ User Story 6: Bilingual Support (P1)
- ✅ User Story 2: Case Management (P1)

This delivers core value: Lawyers can log in, switch languages, and access case information on mobile.

### Incremental Delivery After MVP

- **Iteration 2**: Add Phase 6, 7 (US3 Hearings, US4 Customers) - P2 features
- **Iteration 3**: Add Phase 8, 9 (US5 Notifications, US7 Documents) - P3 features
- **Iteration 4**: Complete Phase 10 (Polish) - Offline sync, conflict resolution, performance optimization

### Full Feature Parity Delivery

After MVP and Polish, implement gap analysis features:
- **Phase 1A**: Employees Management
- **Phase 1B**: Courts Management
- **Phase 1C**: Contenders Management
- **Phase 1D**: Consultations Management
- **Phase 1E**: Trust Accounting
- **Phase 1F**: Client Portal
- **Phase 1G-1K**: Additional features (Governments, Case Relations, Judicial Documents, Reports, Intake)

---

## Task Count Summary

- **Total Tasks**: 202 (136 original + 66 new gap analysis tasks + 50 test tasks)
- **Phase 0 (Gap Analysis)**: 66 tasks
  - Phase 1A: Employees (7 tasks: T137-T143)
  - Phase 1B: Courts (7 tasks: T144-T150)
  - Phase 1C: Contenders (6 tasks: T151-T156)
  - Phase 1D: Consultations (7 tasks: T159-T165)
  - Phase 1E: Trust Accounting (7 tasks: T166-T172)
  - Phase 1F: Client Portal (7 tasks: T173-T179)
  - Phase 1G: Governments (4 tasks: T180-T183)
  - Phase 1H: Case Relations (4 tasks: T184-T187)
  - Phase 1I: Judicial Documents (4 tasks: T188-T191)
  - Phase 1J: Reports (4 tasks: T192-T195)
  - Phase 1K: Intake (4 tasks: T196-T199)
  - Phase 1L: Billing (1 task: T200 - EXISTS)
  - Phase 1M: Time Tracking (1 task: T201 - EXISTS)
  - Phase 1N: Tasks (1 task: T202 - EXISTS)
- **Phase 1 (Setup)**: 9 tasks (T001-T009)
- **Phase 2 (Foundational)**: 25 tasks (T010-T034) [BLOCKING]
- **Phase 3 (US1 - Login/Dashboard)**: 23 tasks (T035-T057) including 5 test tasks (T048-T052)
- **Phase 4 (US6 - Bilingual)**: 8 tasks (T053-T060)
- **Phase 5 (US2 - Cases)**: 17 tasks (T061-T077) including 5 test tasks (T073-T077)
- **Phase 6 (US3 - Hearings)**: 17 tasks (T078-T094) including 5 test tasks (T085-T089)
- **Phase 7 (US4 - Customers)**: 15 tasks (T095-T109) including 5 test tasks (T100-T104)
- **Phase 8 (US5 - Notifications)**: 19 tasks (T110-T128) including 5 test tasks (T119-T123)
- **Phase 9 (US7 - Documents)**: 14 tasks (T129-T142) including 5 test tasks (T133-T137)
- **Phase 10 (Polish)**: 24 tasks (T143-T166)

**MVP Task Count**: 82 tasks (Phase 1, 2, 3, 4, 5 including tests)
**Full Feature Parity**: 202 tasks (including gap analysis features and test coverage per Constitution Principle IV)

---

**End of Tasks Document**

