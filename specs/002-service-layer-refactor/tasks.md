# Tasks: Thin Controller Service Refactor

**Input**: Design documents from `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\`
**Prerequisites**: `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\plan.md`, `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\spec.md`, `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\research.md`, `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\data-model.md`, `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\contracts\controller-service-contract.md`

**Tests**: Backend tests are required for this feature because the specification and constitution require parity-preserving, independently testable migration slices.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the shared refactor workspace and planning anchors used by all migration slices

- [ ] T001 Create the controller migration inventory in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\controller-migration-inventory.md
- [ ] T002 Create the service result rollout notes in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\service-result-rollout.md
- [ ] T003 [P] Create the backend refactor test matrix in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\parity-test-matrix.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared service primitives, dependency wiring, and test utilities that all migrated controllers depend on

**CRITICAL**: No user story work should begin until this phase is complete

- [ ] T004 Create the shared service result contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\ServiceResult.cs
- [ ] T005 [P] Create the validation issue contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\ValidationIssue.cs
- [ ] T006 [P] Create the request-scoped operation context contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\ServiceOperationContext.cs
- [ ] T007 Create the operation-context factory abstraction in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\IServiceOperationContextFactory.cs
- [ ] T008 Implement the operation-context factory in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\ServiceOperationContextFactory.cs
- [ ] T009 Create shared service-registration extensions in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\ServiceCollectionExtensions.cs
- [ ] T010 Wire shared service registrations into D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Program.cs
- [ ] T011 Create shared backend test helpers for InMemory contexts and fake user context in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\Infrastructure\ControllerRefactorTestHost.cs
- [ ] T012 [P] Add foundational tests for service result and operation-context behavior in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\ServiceResultContractTests.cs

**Checkpoint**: Shared service primitives, registrations, and test utilities are ready for controller-family migration slices

---

## Phase 3: User Story 1 - Preserve API Behavior During Refactor (Priority: P1) MVP

**Goal**: Preserve current API routes, payloads, status codes, and localized responses while moving the most controller-heavy business workflows into services

**Independent Test**: Exercise the migrated Governments and CaseRelations endpoints through controller tests and confirm successful, validation, forbidden, and not-found outcomes remain parity-equivalent while service tests cover the extracted workflow rules directly

### Tests for User Story 1

- [ ] T013 [P] [US1] Add Governments service behavior tests in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\GovernmentsServiceTests.cs
- [ ] T014 [P] [US1] Add CaseRelations service behavior tests in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\CaseRelationsServiceTests.cs
- [ ] T015 [US1] Add HTTP-boundary parity tests for GovernmentsController in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\GovernmentsControllerTests.cs
- [ ] T016 [US1] Add HTTP-boundary parity tests for CaseRelationsController in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\CaseRelationsControllerTests.cs

### Implementation for User Story 1

- [ ] T017 [P] [US1] Create the Governments service contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\Governments\IGovernmentsService.cs
- [ ] T018 [P] [US1] Create the CaseRelations service contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\CaseRelations\ICaseRelationsService.cs
- [ ] T019 [US1] Implement location catalog and government workflows in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\Governments\GovernmentsService.cs
- [ ] T020 [US1] Implement case relation workflows and notification orchestration in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\CaseRelations\CaseRelationsService.cs
- [ ] T021 [US1] Refactor controller HTTP mapping to delegate through the new service in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Controllers\GovernmentsController.cs
- [ ] T022 [US1] Refactor controller HTTP mapping to delegate through the new service in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Controllers\CaseRelationsController.cs
- [ ] T023 [US1] Register Governments and CaseRelations services in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Program.cs

**Checkpoint**: Governments and CaseRelations controller families are thin, parity-tested, and safe to ship as the MVP slice

---

## Phase 4: User Story 2 - Reuse Business Rules Outside Controllers (Priority: P2)

**Goal**: Introduce reusable access-evaluation and orchestration services that multiple controller families can share without duplicating business logic

**Independent Test**: Invoke the shared access evaluators and service workflows from tests without going through controllers, and confirm multiple controller families can depend on the same tenant, authorization, and result-mapping primitives consistently

### Tests for User Story 2

- [ ] T024 [P] [US2] Add shared case access evaluator tests in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\CaseAccessServiceTests.cs
- [ ] T025 [P] [US2] Add shared tenant ownership evaluator tests in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\TenantOwnershipServiceTests.cs
- [ ] T026 [US2] Add service-first regression tests for Cases workflows that consume shared access rules in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\CasesServiceTests.cs

### Implementation for User Story 2

- [ ] T027 [P] [US2] Create the shared case access service contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\ICaseAccessService.cs
- [ ] T028 [P] [US2] Create the shared tenant ownership service contract in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Abstractions\ITenantOwnershipService.cs
- [ ] T029 [US2] Implement reusable case access evaluation in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\CaseAccessService.cs
- [ ] T030 [US2] Implement reusable tenant ownership evaluation in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\TenantOwnershipService.cs
- [ ] T031 [US2] Create the Cases service contract for extracted workflows in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\Cases\ICasesService.cs
- [ ] T032 [US2] Implement reusable case workflow orchestration in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\Cases\CasesService.cs
- [ ] T033 [US2] Refactor CasesController to consume shared service workflows in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Controllers\CasesController.cs
- [ ] T034 [US2] Register the shared access evaluators and Cases service in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Program.cs

**Checkpoint**: Shared business rules are reusable across controller families and are directly testable outside the HTTP layer

---

## Phase 5: User Story 3 - Improve Maintainability and Supportability (Priority: P3)

**Goal**: Roll the thin-controller pattern across additional controller families and leave maintainable guardrails for future work

**Independent Test**: Review representative migrated controllers and confirm business logic lives in service entry points, controller tests only cover HTTP boundaries, and maintainers can trace workflows quickly through the service layer

### Tests for User Story 3

- [ ] T035 [P] [US3] Add trust-accounting service tests for extracted workflow behavior in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\TrustAccountingServiceTests.cs
- [ ] T036 [P] [US3] Add controller-boundary regression tests for the thin TrustAccountingController in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\TrustAccountingControllerTests.cs
- [ ] T037 [US3] Add architecture review coverage for thin-controller expectations in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\tests\LawyerSys.Tests\ControllerThinnessReviewTests.cs

### Implementation for User Story 3

- [ ] T038 [P] [US3] Create the TrustAccounting service contract for extracted workflows in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\TrustAccounting\ITrustAccountingService.cs
- [ ] T039 [US3] Implement trust accounting orchestration behind the service boundary in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Services\TrustAccounting\TrustAccountingService.cs
- [ ] T040 [US3] Refactor TrustAccountingController to keep only HTTP concerns in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Controllers\TrustAccountingController.cs
- [ ] T041 [US3] Apply the thin-controller migration checklist to the remaining controllers recorded in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\controller-migration-inventory.md
- [ ] T042 [US3] Document the maintained controller-to-service conventions in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\DOCS\DEVELOPMENT_GUIDE.md

**Checkpoint**: Representative controller families are migrated, the remaining rollout is tracked, and maintainers have explicit guardrails for continuing the pattern

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize verification, documentation, and cross-cutting consistency after the story slices are complete

- [ ] T043 [P] Update the controller-service contract with any approved rollout refinements in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\contracts\controller-service-contract.md
- [ ] T044 Reconcile bilingual message-key usage between controllers and services in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys\Resources\SharedResource.resx
- [ ] T045 [P] Reconcile bilingual message-key usage between controllers and services in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\LawyerSys.Service\Resources\SharedResource.resx
- [ ] T046 Run backend validation steps and record results in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\quickstart.md
- [ ] T047 Update the rollout inventory with completed controller families and remaining follow-up in D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\controller-migration-inventory.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies; start immediately.
- **Phase 2: Foundational**: Depends on Phase 1 and blocks all user story implementation.
- **Phase 3: User Story 1**: Starts after Phase 2; this is the MVP slice.
- **Phase 4: User Story 2**: Starts after Phase 2 and builds on the shared primitives; it may proceed after or alongside late US1 cleanup if there is staffing capacity.
- **Phase 5: User Story 3**: Starts after Phase 2 and should follow the reusable patterns established in US1 and US2.
- **Phase 6: Polish**: Starts after the desired user story slices are complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories; establishes the first parity-preserving migration slice.
- **US2 (P2)**: Depends on foundational primitives and benefits from the service-result pattern proven in US1.
- **US3 (P3)**: Depends on foundational primitives and should reuse the patterns established in US1 and US2 for broader maintainability.

### Within Each User Story

- Service tests should be added before or alongside service extraction and should fail until the new workflow exists.
- Service contracts should exist before service implementations.
- Service implementations should be completed before the controller is thinned.
- Controller-boundary tests should confirm HTTP parity after the service extraction is in place.

## Parallel Opportunities

- **Setup**: T003 can run while T001-T002 are prepared.
- **Foundational**: T005 and T006 can run in parallel after T004 starts the shared contract shape; T011 and T012 can proceed once the core abstractions are defined.
- **US1**: T013 and T014 can run in parallel; T017 and T018 can run in parallel; T021 and T022 can proceed independently once their services are implemented.
- **US2**: T024 and T025 can run in parallel; T027 and T028 can run in parallel; T029 and T030 can run in parallel.
- **US3**: T035 and T036 can run in parallel; T038 can be prepared while T037 defines the maintainability review coverage.
- **Polish**: T043 and T045 can run in parallel.

## Parallel Example: User Story 1

```text
T013 + T014: service behavior tests for Governments and CaseRelations
T017 + T018: create the two service contracts in parallel
```

## Parallel Example: User Story 2

```text
T024 + T025: shared evaluator tests in parallel
T027 + T028: shared service contracts in parallel
```

## Parallel Example: User Story 3

```text
T035 + T036: trust-accounting service and controller-boundary tests in parallel
T038: prepare the TrustAccounting service contract once the shared primitives are complete
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Validate parity for Governments and CaseRelations before expanding the rollout.

### Incremental Delivery

1. Establish shared service primitives and test helpers.
2. Ship the first thin-controller slice with Governments and CaseRelations.
3. Add reusable access services and migrate Cases workflows.
4. Extend the pattern to TrustAccounting and the remaining controller inventory.
5. Finish with cross-cutting localization, documentation, and validation updates.

### Parallel Team Strategy

1. One developer handles shared service primitives and DI wiring.
2. One developer migrates Governments workflows while another migrates CaseRelations workflows after the foundational phase.
3. Additional developers can take shared access services, Cases workflows, and TrustAccounting once the service-result pattern is established.

## Notes

- All tasks use the required checklist format with sequential IDs, optional `[P]` markers, and `[US#]` labels only in story phases.
- The suggested MVP scope is **User Story 1**.
- Keep controller route attributes, model binding, and status-code mapping in controllers; move all business processing to services.
