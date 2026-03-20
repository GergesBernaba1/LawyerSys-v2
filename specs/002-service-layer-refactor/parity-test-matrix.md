# Backend Refactor Test Matrix

## Foundational Coverage

| Area | Expected proof |
|---|---|
| Service result contract | Unit tests for status, message metadata, and validation issue shape |
| Operation context factory | Unit tests for user, role, tenant, and culture extraction |

## User Story 1 Coverage

| Controller family | Service tests | Controller-boundary tests | Parity focus |
|---|---|---|---|
| `GovernmentsController` | Required | Required | pagination, duplicate validation, tenant city ownership, localized failure mapping |
| `CaseRelationsController` | Required | Required | duplicate relation rules, case access checks, notification-triggered workflows, not-found mapping |

## Expansion Coverage

| Controller family | Planned proof |
|---|---|
| `CasesController` | shared access-evaluator tests plus service-first workflow tests |
| `TrustAccountingController` | extracted workflow tests plus controller-boundary regression tests |
