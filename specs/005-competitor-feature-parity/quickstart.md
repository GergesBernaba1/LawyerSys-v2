# Quickstart: Competitor Feature Parity and Improvement

## Prerequisites

- Feature branch: `005-competitor-feature-parity`
- .NET SDK aligned with solution (`global.json`)
- Node/npm for `LawyerSys/ClientApp`

## 1. Review Spec and Plan Artifacts

- Read `specs/005-competitor-feature-parity/spec.md`
- Read `specs/005-competitor-feature-parity/plan.md`
- Read `specs/005-competitor-feature-parity/research.md`
- Read `specs/005-competitor-feature-parity/data-model.md`
- Read `specs/005-competitor-feature-parity/contracts/parity-roadmap.openapi.yaml`

## 2. Implement Vertical Slice

1. Backend domain/application updates:
   - Add/extend entities for capability catalog, coverage assessment, roadmap item, outcome metric, and change log.
   - Enforce tenant scope and RBAC checks for all parity-governance endpoints.
2. API layer:
   - Implement endpoints defined in the OpenAPI contract.
   - Enforce lifecycle completion gate (`released` + metrics met).
3. Frontend:
   - Add parity governance UI flows for role-specific listing/editing.
   - Add localized labels/messages for Arabic and English.
4. Auditability:
   - Emit change-log entries for roadmap mutations and lock operations.

## 3. Validate

- Backend tests:
  - `dotnet test`
- Frontend checks:
  - `npm --prefix LawyerSys/ClientApp run lint`
  - `npm --prefix LawyerSys/ClientApp test`
- Optional UI flow verification:
  - `npm --prefix LawyerSys/ClientApp run test:e2e`

## 4. Acceptance Validation

- Confirm weekly refresh endpoint/task updates priority ranking.
- Confirm role restrictions (Admin/Partner/Operations/Analyst/Viewer) are enforced.
- Confirm roadmap completion cannot occur without KPI success.
- Confirm no cross-tenant visibility/edit leakage in listing or mutation operations.
