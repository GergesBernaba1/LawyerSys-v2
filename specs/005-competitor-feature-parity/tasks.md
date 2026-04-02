# Tasks: Competitor Feature Parity and Improvement

**Input**: Design documents from `/specs/005-competitor-feature-parity/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/parity-roadmap.openapi.yaml

**Tests**: Included. This feature touches tenant isolation, RBAC, lifecycle gates, and critical operator workflows, so backend and frontend automated tests are part of delivery.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare feature scaffolding and shared contracts for parity governance.

- [X] T001 Add parity API/client route constants in LawyerSys/ClientApp/src/services/api.ts
- [X] T002 Create shared parity DTO definitions in LawyerSys/ClientApp/src/types/parity.ts
- [X] T003 [P] Add backend parity DTO contracts in LawyerSys/Services/Parity/ParityDtos.cs
- [X] T004 [P] Create backend parity service interface in LawyerSys/Services/Parity/IParityRoadmapService.cs
- [X] T005 Create OpenAPI alignment checklist notes in specs/005-competitor-feature-parity/contracts/parity-roadmap.openapi.yaml

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure required before implementing user-story-specific flows.

- [X] T006 Add parity domain entities in LawyerSys.Domain/Entities/Parity/ParityEntities.cs
- [X] T007 Configure parity entity mappings in LawyerSys.Infrastructure/Persistence/Configurations/Parity/ParityEntityConfigurations.cs
- [X] T008 Add DbSet registrations in LawyerSys.Infrastructure/Persistence/ApplicationDbContext.cs
- [X] T009 Create parity migration for core tables in LawyerSys.Infrastructure/Migrations/*ParityRoadmap*.cs
- [X] T010 Implement tenant-scoped repository helpers in LawyerSys.Infrastructure/Repositories/Parity/ParityRepository.cs
- [X] T011 Implement RBAC policy constants for parity roles in LawyerSys/Extensions/Authorization/ParityPolicies.cs
- [X] T012 Wire parity service registration and policies in LawyerSys/Program.cs
- [X] T013 Create audit change-log writer for parity updates in LawyerSys/Services/Parity/ParityChangeLogWriter.cs

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Define a prioritized parity roadmap (Priority: P1) ðŸŽ¯ MVP

**Goal**: Deliver capability cataloging, coverage scoring, and prioritized roadmap generation.

**Independent Test**: A tenant admin can create/list capabilities, assess coverage, generate roadmap priorities, and retrieve ranked roadmap items without cross-tenant leakage.

### Tests for User Story 1

- [X] T014 [P] [US1] Add capabilities endpoint tests in tests/LawyerSys.Tests/ParityCapabilitiesControllerTests.cs
- [X] T015 [P] [US1] Add coverage assessment service tests in tests/LawyerSys.Tests/ParityCoverageAssessmentServiceTests.cs
- [X] T016 [P] [US1] Add roadmap ranking service tests in tests/LawyerSys.Tests/ParityRoadmapRankingServiceTests.cs
- [X] T017 [P] [US1] Add frontend parity catalog flow test in LawyerSys/ClientApp/tests/parity-catalog.spec.ts

### Implementation for User Story 1

- [X] T018 [US1] Implement capability catalog service methods in LawyerSys/Services/Parity/ParityRoadmapService.Capabilities.cs
- [X] T019 [US1] Implement assessment scoring methods in LawyerSys/Services/Parity/ParityRoadmapService.Assessments.cs
- [X] T020 [US1] Implement roadmap ranking aggregation in LawyerSys/Services/Parity/ParityRoadmapService.Ranking.cs
- [X] T021 [US1] Add capability endpoints in LawyerSys/Controllers/ParityCapabilitiesController.cs
- [X] T022 [US1] Add assessment endpoints in LawyerSys/Controllers/ParityAssessmentsController.cs
- [X] T023 [US1] Add roadmap list/create endpoints in LawyerSys/Controllers/ParityRoadmapController.cs
- [X] T024 [P] [US1] Implement parity API client methods in LawyerSys/ClientApp/src/services/parityService.ts
- [X] T025 [P] [US1] Build parity roadmap page shell in LawyerSys/ClientApp/app/parity-roadmap/page.tsx
- [X] T026 [US1] Implement coverage status and ranking table UI in LawyerSys/ClientApp/src/components/parity/ParityRoadmapTable.tsx

**Checkpoint**: US1 is independently functional and testable (MVP).

---

## Phase 4: User Story 2 - Improve existing high-impact workflows (Priority: P2)

**Goal**: Enable workflow improvement items with measurable baseline/target/observed metrics and completion outcomes.

**Independent Test**: Operations users can create improvement items, attach metrics, and verify workflow improvements via outcome reporting.

### Tests for User Story 2

- [X] T027 [P] [US2] Add roadmap metrics endpoint tests in tests/LawyerSys.Tests/ParityRoadmapMetricsControllerTests.cs
- [X] T028 [P] [US2] Add completion-gate service tests in tests/LawyerSys.Tests/ParityRoadmapCompletionGateTests.cs
- [X] T029 [P] [US2] Add frontend metrics entry flow test in LawyerSys/ClientApp/tests/parity-metrics.spec.ts

### Implementation for User Story 2

- [X] T030 [US2] Implement outcome metric service methods in LawyerSys/Services/Parity/ParityRoadmapService.Metrics.cs
- [X] T031 [US2] Implement completion-state gate rules in LawyerSys/Services/Parity/ParityRoadmapService.Lifecycle.cs
- [X] T032 [US2] Add metrics record endpoint in LawyerSys/Controllers/ParityRoadmapMetricsController.cs
- [X] T033 [US2] Add lifecycle transition endpoint with KPI validation in LawyerSys/Controllers/ParityRoadmapStateController.cs
- [X] T034 [P] [US2] Build metrics editor UI in LawyerSys/ClientApp/src/components/parity/ParityMetricsEditor.tsx
- [X] T035 [US2] Add workflow improvement panel integration in LawyerSys/ClientApp/app/parity-roadmap/page.tsx

**Checkpoint**: US2 is independently functional and testable.

---

## Phase 5: User Story 3 - Introduce differentiated value beyond parity (Priority: P3)

**Goal**: Add differentiation initiative support, role-scoped visibility, edit locking, and weekly evidence refresh workflow.

**Independent Test**: Partner/analyst users can manage differentiation initiatives with role-scoped access, safe concurrent edits, and weekly refresh updates.

### Tests for User Story 3

- [X] T036 [P] [US3] Add RBAC visibility tests for parity endpoints in tests/LawyerSys.Tests/ParityRoadmapRbacTests.cs
- [X] T037 [P] [US3] Add edit lock conflict tests in tests/LawyerSys.Tests/ParityRoadmapLockingTests.cs
- [X] T038 [P] [US3] Add refresh endpoint tests in tests/LawyerSys.Tests/ParityRefreshControllerTests.cs
- [X] T039 [P] [US3] Add frontend role-visibility and locking flow test in LawyerSys/ClientApp/tests/parity-rbac-locking.spec.ts

### Implementation for User Story 3

- [X] T040 [US3] Implement role-filtered roadmap query logic in LawyerSys/Services/Parity/ParityRoadmapService.Visibility.cs
- [X] T041 [US3] Implement edit lock acquire/release and timeout rules in LawyerSys/Services/Parity/ParityRoadmapService.Locking.cs
- [X] T042 [US3] Implement weekly refresh orchestration in LawyerSys/Services/Parity/ParityWeeklyRefreshService.cs
- [X] T043 [US3] Add lock endpoint in LawyerSys/Controllers/ParityRoadmapLockController.cs
- [X] T044 [US3] Add refresh trigger endpoint in LawyerSys/Controllers/ParityRefreshController.cs
- [X] T045 [P] [US3] Build role-based action visibility UI in LawyerSys/ClientApp/src/components/parity/ParityActionToolbar.tsx
- [X] T046 [US3] Add lock-state and refresh controls to page in LawyerSys/ClientApp/app/parity-roadmap/page.tsx

**Checkpoint**: US3 is independently functional and testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening, localization, and end-to-end validation across all stories.

- [X] T047 [P] Add Arabic/English localization keys for parity flows in LawyerSys/ClientApp/src/locales/en/translation.json
- [X] T048 [P] Add Arabic parity localization entries in LawyerSys/ClientApp/src/locales/ar/translation.json
- [X] T049 Add structured parity audit logging enrichment in LawyerSys/Realtime/SignalRNotificationRealtimePublisher.cs
- [X] T050 Add/update API documentation for parity endpoints in LawyerSys/DOCS/FEATURE_ROADMAP.md
- [X] T051 Run backend regression tests for parity slice in tests/LawyerSys.Tests/LawyerSys.Tests.csproj
- [ ] T052 Run frontend lint and test suites for parity slice in LawyerSys/ClientApp/package.json
- [ ] T053 Run quickstart validation checklist in specs/005-competitor-feature-parity/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2; delivers MVP.
- **Phase 4 (US2)**: Depends on Phase 3 service primitives and may run after US1 MVP validation.
- **Phase 5 (US3)**: Depends on foundational lifecycle/service primitives from US1/US2.
- **Phase 6 (Polish)**: Depends on completion of targeted user stories.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational completion.
- **US2 (P2)**: Uses roadmap primitives from US1 but remains independently testable.
- **US3 (P3)**: Uses roadmap primitives and role model from earlier phases but remains independently testable.

### Within Each User Story

- Tests first (write and run failing tests before implementation tasks).
- Service logic before controllers/UI wiring.
- Backend endpoints before frontend integration.
- Story-specific checkpoint validation before proceeding.

### Parallel Opportunities

- Setup tasks marked `[P]` can run concurrently (`T003`, `T004`).
- Foundational tasks marked `[P]` are independent (`T011` with `T013` after `T006-T010`).
- For each user story, test tasks marked `[P]` can run in parallel.
- UI component tasks marked `[P]` can run parallel to backend endpoint tasks when contracts are stable.

---

## Parallel Example: User Story 1

```bash
# Parallel US1 tests
T014 + T015 + T016 + T017

# Parallel US1 UI/API client work once endpoints are defined
T024 + T025
```

## Parallel Example: User Story 3

```bash
# Parallel US3 validation
T036 + T037 + T038 + T039

# Parallel UI/backend after service contracts stabilize
T044 + T045
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Deliver Phase 3 (US1) completely.
3. Validate independent test criteria for US1.
4. Demo MVP parity roadmap slice before US2/US3 expansion.

### Incremental Delivery

1. US1 (parity catalog + ranking)
2. US2 (workflow improvement metrics + completion gate)
3. US3 (differentiation, RBAC visibility, locking, weekly refresh)
4. Polish and regression validation.

### Format Validation

- All tasks use required checklist format: `- [ ] Txxx [P?] [US?] Description with file path`.
- Setup/foundational/polish tasks have no story label.
- User-story tasks include `[US1]`, `[US2]`, or `[US3]` labels.
