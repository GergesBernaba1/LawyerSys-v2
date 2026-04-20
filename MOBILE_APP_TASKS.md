# Mobile App — Parity Tasks with Web App

> Goal: bring the Flutter `MobileApp/` to feature parity with the `LawyerSys/` web app.
> Generated: 2026-04-19. Scope: missing modules, incomplete modules, and quality/enhancement work.
> Legend — Priority: **P0** critical, **P1** high, **P2** medium, **P3** low.

---

## 1. Missing Modules (exist on web, absent in mobile)

| # | Module | Priority | Scope |
|---|--------|----------|-------|
| 1.1 | ~~**ai-assistant**~~ ✅ | P1 | Drafting, summarization, task suggestion screens + service wrapper around `AIAssistantController`. |
| 1.2 | ~~**document-generation**~~ ✅ | P1 | Template picker, field-fill screen, generated-document preview + `DocumentGenerationController` integration. |
| 1.3 | ~~**esign**~~ ✅ | P1 | Request creation, signer list, sign flow, status tracking against `ESignController`. |
| 1.4 | ~~**files**~~ ✅ | P1 | File browser, upload/download, folder navigation via `FilesController`. |
| 1.5 | ~~**court-automation**~~ ✅ | P1 | Automated filing submission + status tracking against `CourtAutomationController`. |
| 1.6 | ~~**employee-workqueue**~~ ✅ | P1 | Assigned task queue, accept/complete flow, reassignment. |
| 1.7 | ~~**administration**~~ ✅ | P2 | Admin dashboard, system toggles, tenant-level config. |
| 1.8 | ~~**auditlogs**~~ ✅ | P2 | Audit trail list + filters (user, entity, date). Read-only. |
| 1.9 | ~~**sitings**~~ ✅ | P2 | Court sittings list/detail/form. |
| 1.10 | ~~**subscription**~~ ✅ | P2 | Package list, current plan, upgrade/cancel flow. |
| 1.11 | ~~**trust-reports**~~ ✅ | P2 | Trust account reporting screen (distinct from trust-accounting transactions). |
| 1.12 | ~~**about-us**~~ ✅ | P3 | Static informational screen. |
| 1.13 | ~~**contact-us**~~ ✅ | P3 | Public contact form. |

---

## 2. Incomplete Modules (partial parity)

### 2.1 Customers — **P0**
- [x] Add create-customer form screen
- [x] Add edit-customer form screen
- [x] Profile image upload
- [ ] Case notification preferences
- [ ] Payment-proof submission workflow
- [ ] Requested-document workflow

### 2.2 Employees — **P0**
- [x] Create-employee form
- [x] Edit-employee form
- [x] Profile image upload
- [x] Link to workqueue / assigned tasks

### 2.3 Courts — **P0**
- [x] Replace stub `court_form_screen` (15-line placeholder) with full create/edit form
- [x] Localize "Add Court" / "Edit Court" labels

### 2.4 Governments — **P1**
- [x] Detail screen
- [x] Create form
- [x] Edit form
- [x] Delete action

### 2.5 Users — **P0**
- [x] Introduce Bloc + Model layer (currently uses `setState` directly)
- [x] Create / edit / delete
- [x] Role management
- [x] Localize AppBar + messages

### 2.6 Tenants — **P0**
- [x] Introduce Bloc + Model layer
- [x] Detail screen, create/edit flow
- [x] Subscription management hook-in
- [x] Localize hardcoded strings ("Tenants", "Tenant status updated", "No tenants found")

### 2.7 Intake — **P1**
- [x] Lead list view
- [x] Lead detail view
- [x] Conflict-check UI
- [x] Lead assignment workflow
- [x] Public intake link generation

### 2.8 Client Portal — **P1**
- [x] Real document download (url_launcher integration)
- [x] Message compose + reply
- [x] File upload to portal

### 2.9 Calendar — **P1**
- [x] Event creation
- [x] Event edit
- [x] Event delete
- [x] Date-specific event details sheet

### 2.10 Documents — **P1**
- [x] Upload from device
- [x] Create/rename
- [ ] Version history
- [x] Share / external link

### 2.11 Case Relations — **P2**
- [x] Detail screen
- [x] Create / delete relation

### 2.12 Judicial Documents — **P2**
- [x] Detail screen
- [x] Create / edit / delete

### 2.13 Consultations — **P2**
- [x] Expand detail screen
- [x] Edit flow (full create/edit/delete in list screen)

### 2.14 Contenders — **P2**
- [x] Expand detail screen
- [x] Fix field mapping: `birthDate` label corrected

---

## 3. Architecture & Code-Quality

- [x] **P0** — Enforce Bloc pattern across `tenants`, `users` (done); `settings` remains.
- [x] **P1** — Audit `MobileApp/lib/core/utils/` (untracked `normalizeJsonList` utility) — add unit tests covering both `items`-wrapped and bare-array API responses. Now used by billing, calendar, customers, hearings, trust-accounting repositories.
- [x] **P1** — Add unit tests for repositories and Blocs (18 tests: json_utils × 8, customers_bloc × 4, workqueue_bloc × 3, calendar_bloc × 3 — all passing).
- [x] **P2** — Add integration tests for critical flows (login, case CRUD, billing) — stubs in `integration_test/app_test.dart`; skipped until backend available.
- [x] **P2** — Introduce shared error-handling + loading-state widgets; replace ad-hoc `CircularProgressIndicator` usages.

## 4. Localization

- [x] **P1** — Sweep hardcoded English strings in `tenants_screen`, `users_screen`, `courts/court_form_screen` (done); portal document screens remain.
- [x] **P1** — Add missing localization keys for newly added screens (20 new keys: documents share/upload, tenants CRUD, users role, case relations).

## 5. UX Enhancements

- [x] **P1** — Navigation drawer wired to all modules (intake, files, esign, ai-assistant, doc-generation, court-automation, sitings, workqueue, administration, subscription, trust-reports, audit-logs, about, contact).
- [x] **P1** — Implement real file downloads in client portal (replace snackbar stub).
- [x] **P2** — Form validation pass on all create/edit forms.
- [x] **P2** — Consistent empty-state illustrations across list screens.
- [x] **P2** — Pull-to-refresh on all list screens (sweep: contenders, reports, workqueue, administration, subscription, sitings, judicial docs, employees).
- [ ] **P3** — Dark mode verification across all new screens.

## 6. Cross-cutting / Platform

- [x] **P1** — Offline caching strategy for read-heavy screens (cases list ✅ prior, calendar ✅ now — SQLite fallback with `calendar_events` table, DB migration v1→v2).
- [x] **P2** — Push notifications wired to `NotificationsController` (Firebase Messaging + NotificationsBloc + inbox screen + bell badge + SignalR real-time updates — already implemented).
- [x] **P2** — Deep-link handling (`lawyersys://` custom scheme intent filter in AndroidManifest; parameterized route handler in `onGenerateRoute`).
- [ ] **P3** — Analytics/telemetry hooks.

---

## Suggested Sequencing

1. **Sprint 1 (P0 foundations)**: Users/Tenants Bloc refactor, Customers CRUD, Employees CRUD, Courts form.
2. **Sprint 2 (P1 core gaps)**: Calendar CRUD, Documents upload, Portal downloads, Intake list/detail, Governments CRUD.
3. **Sprint 3 (P1 modules)**: Files, Document Generation, E-Sign, AI Assistant, Court Automation, Employee Workqueue.
4. **Sprint 4 (P2)**: Administration, Auditlogs, Sitings, Subscription, Trust Reports, remaining detail screens.
5. **Sprint 5 (P3 + quality)**: About/Contact, localization sweep, test coverage, offline, deep-links.

## References
- Source inventory: `LawyerSys/` controllers (44) and `ClientApp/` feature folders (38).
- Mobile inventory: `MobileApp/lib/features/` (26 modules).
- Prior plan: [MOBILE_APP_FEATURE_PLAN.md](MOBILE_APP_FEATURE_PLAN.md).
