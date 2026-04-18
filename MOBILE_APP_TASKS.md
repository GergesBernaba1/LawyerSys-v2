# Mobile App — Parity Tasks with Web App

> Goal: bring the Flutter `MobileApp/` to feature parity with the `LawyerSys/` web app.
> Generated: 2026-04-19. Scope: missing modules, incomplete modules, and quality/enhancement work.
> Legend — Priority: **P0** critical, **P1** high, **P2** medium, **P3** low.

---

## 1. Missing Modules (exist on web, absent in mobile)

| # | Module | Priority | Scope |
|---|--------|----------|-------|
| 1.1 | **ai-assistant** | P1 | Drafting, summarization, task suggestion screens + service wrapper around `AIAssistantController`. |
| 1.2 | **document-generation** | P1 | Template picker, field-fill screen, generated-document preview + `DocumentGenerationController` integration. |
| 1.3 | **esign** | P1 | Request creation, signer list, sign flow, status tracking against `ESignController`. |
| 1.4 | **files** | P1 | File browser, upload/download, folder navigation via `FilesController`. |
| 1.5 | **court-automation** | P1 | Automated filing submission + status tracking against `CourtAutomationController`. |
| 1.6 | **employee-workqueue** | P1 | Assigned task queue, accept/complete flow, reassignment. |
| 1.7 | **administration** | P2 | Admin dashboard, system toggles, tenant-level config. |
| 1.8 | **auditlogs** | P2 | Audit trail list + filters (user, entity, date). Read-only. |
| 1.9 | **sitings** | P2 | Court sittings list/detail/form. |
| 1.10 | **subscription** | P2 | Package list, current plan, upgrade/cancel flow. |
| 1.11 | **trust-reports** | P2 | Trust account reporting screen (distinct from trust-accounting transactions). |
| 1.12 | **about-us** | P3 | Static informational screen. |
| 1.13 | **contact-us** | P3 | Public contact form. |

---

## 2. Incomplete Modules (partial parity)

### 2.1 Customers — **P0**
- [x] Add create-customer form screen
- [x] Add edit-customer form screen
- [ ] Profile image upload
- [ ] Case notification preferences
- [ ] Payment-proof submission workflow
- [ ] Requested-document workflow

### 2.2 Employees — **P0**
- [ ] Create-employee form
- [ ] Edit-employee form
- [ ] Profile image upload
- [ ] Link to workqueue / assigned tasks

### 2.3 Courts — **P0**
- [x] Replace stub `court_form_screen` (15-line placeholder) with full create/edit form
- [x] Localize "Add Court" / "Edit Court" labels

### 2.4 Governments — **P1**
- [ ] Detail screen
- [x] Create form
- [x] Edit form
- [x] Delete action

### 2.5 Users — **P0**
- [x] Introduce Bloc + Model layer (currently uses `setState` directly)
- [ ] Create / edit / delete
- [ ] Role management
- [x] Localize AppBar + messages

### 2.6 Tenants — **P0**
- [x] Introduce Bloc + Model layer
- [ ] Detail screen, create/edit flow
- [ ] Subscription management hook-in
- [x] Localize hardcoded strings ("Tenants", "Tenant status updated", "No tenants found")

### 2.7 Intake — **P1**
- [ ] Lead list view
- [ ] Lead detail view
- [ ] Conflict-check UI
- [ ] Lead assignment workflow
- [ ] Public intake link generation

### 2.8 Client Portal — **P1**
- [ ] Real document download (currently only shows "Download started" snackbar)
- [ ] Message compose + reply
- [ ] File upload to portal

### 2.9 Calendar — **P1**
- [ ] Event creation
- [ ] Event edit
- [ ] Event delete
- [ ] Date-specific event details sheet

### 2.10 Documents — **P1**
- [ ] Upload from device
- [ ] Create/rename
- [ ] Version history
- [ ] Share / external link

### 2.11 Case Relations — **P2**
- [ ] Detail screen
- [ ] Create / edit / delete relation

### 2.12 Judicial Documents — **P2**
- [ ] Detail screen
- [ ] Create / edit / delete

### 2.13 Consultations — **P2**
- [ ] Expand detail screen (currently 82 lines, read-only)
- [ ] Edit flow

### 2.14 Contenders — **P2**
- [ ] Expand detail screen (39 lines)
- [ ] Fix field mapping: `birthDate` rendered as "startDate" label

---

## 3. Architecture & Code-Quality

- [x] **P0** — Enforce Bloc pattern across `tenants`, `users` (done); `settings` remains.
- [ ] **P1** — Audit `MobileApp/lib/core/utils/` (untracked `normalizeJsonList` utility) — add unit tests covering both `items`-wrapped and bare-array API responses. Now used by billing, calendar, customers, hearings, trust-accounting repositories.
- [ ] **P1** — Add unit tests for repositories and Blocs (no test coverage today).
- [ ] **P2** — Add integration tests for critical flows (login, case CRUD, billing).
- [ ] **P2** — Introduce shared error-handling + loading-state widgets; replace ad-hoc `CircularProgressIndicator` usages.

## 4. Localization

- [x] **P1** — Sweep hardcoded English strings in `tenants_screen`, `users_screen`, `courts/court_form_screen` (done); portal document screens remain.
- [ ] **P1** — Add missing localization keys for newly added screens; run audit script to catch regressions.

## 5. UX Enhancements

- [ ] **P1** — Implement real file downloads in client portal (replace snackbar stub).
- [ ] **P2** — Form validation pass on all create/edit forms.
- [ ] **P2** — Consistent empty-state illustrations across list screens.
- [ ] **P2** — Pull-to-refresh on all list screens.
- [ ] **P3** — Dark mode verification across all new screens.

## 6. Cross-cutting / Platform

- [ ] **P1** — Offline caching strategy for read-heavy screens (cases list, calendar).
- [ ] **P2** — Push notifications wired to `NotificationsController`.
- [ ] **P2** — Deep-link handling (case, hearing, document URLs).
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
