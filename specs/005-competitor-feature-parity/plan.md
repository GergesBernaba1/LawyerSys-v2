# Implementation Plan: Competitor Feature Parity and Improvement

**Branch**: `005-competitor-feature-parity` | **Date**: 2026-04-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-competitor-feature-parity/spec.md`

## Summary

Deliver a Saudi-first competitor parity governance slice that catalogs competitor capabilities, scores current coverage, prioritizes parity vs. differentiation, enforces fine-grained role access, applies weekly evidence refresh, and only marks roadmap completion after measured outcomes are met.

## Technical Context

**Language/Version**: C# 12 on .NET 8 (backend), TypeScript 5.x (Next.js 14.2 / React 18 web client)  
**Primary Dependencies**: ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, Material UI, i18next, axios  
**Storage**: PostgreSQL through `ApplicationDbContext` and `LegacyDbContext`  
**Testing**: xUnit + Moq (backend), Playwright + npm test/lint (frontend)  
**Target Platform**: Multi-tenant web application (backend API + web client), bilingual Arabic/English operation
**Project Type**: Web application (API + frontend)  
**Performance Goals**: Weekly ranking refresh completes within operational window; priority dashboards load in under 3 seconds for office users  
**Constraints**: Tenant isolation on all reads/writes, RBAC enforcement for Admin/Partner/Operations/Analyst/Viewer, Saudi compliance baseline, auditable change log, no cross-tenant data leakage  
**Scale/Scope**: Current multi-firm tenant base, competitor capability catalog across case management/client communication/billing/compliance/reporting/operations, weekly review cycle

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `I. Tenant Isolation Is Mandatory`: PASS. Plan scopes all capability catalog, assessments, and roadmap updates to explicit tenant context; no shared mutable records across tenants.
- `II. Secure And Auditable Access By Default`: PASS. Plan enforces JWT/Identity-based RBAC and mandatory change-log entries for roadmap edits.
- `III. Parity-Preserving Migration`: PASS. Plan extends existing workflow by adding parity governance without replacing legacy legal operations behavior.
- `IV. Testable Vertical Slices`: PASS. Plan defines one vertical slice with backend/API/frontend + automated tests for coverage mapping, ranking, RBAC visibility, and completion-state rules.
- `V. Bilingual Operator UX`: PASS. Plan requires localizable labels/statuses and Arabic/English-ready states for roadmap and assessment screens.

Post-Design Re-check (after Phase 1 artifacts): PASS. `research.md`, `data-model.md`, `contracts/`, and `quickstart.md` preserve all constitution gates with no required exceptions.

## Project Structure

### Documentation (this feature)

```text
specs/005-competitor-feature-parity/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── parity-roadmap.openapi.yaml
└── tasks.md
```

### Source Code (repository root)

```text
LawyerSys/
├── Controllers/
├── Services/
├── Data/
├── Realtime/
└── ClientApp/
    ├── app/
    ├── src/
    └── tests/

LawyerSys.Domain/
LawyerSys.Infrastructure/
LawyerSys.Service/
tests/
```

**Structure Decision**: Use existing ASP.NET Core + Next.js monorepo layout. Implement parity governance via backend controllers/services and corresponding client pages/services/tests in `LawyerSys/ClientApp`, with shared domain/infrastructure updates where required.

## Phase 0: Research Plan

- Research Task 1: Define governance model for competitor capability cataloging and parity scoring in a multi-tenant legal SaaS context.
- Research Task 2: Define best practices for RBAC + auditability on prioritization workflows with cross-role visibility constraints.
- Research Task 3: Define measurable completion rules linking release status to outcome KPIs and review windows.
- Research Task 4: Define weekly refresh operating model for competitor evidence updates and ranking recalculation.

Output: `research.md` with all decisions and no unresolved `NEEDS CLARIFICATION` items.

## Phase 1: Design & Contracts

- Build entity model and constraints in `data-model.md` for Competitor Capability, Coverage Assessment, Roadmap Item, Outcome Metric, and Change Log.
- Define API contract in `contracts/parity-roadmap.openapi.yaml` for catalog, assessment, ranking, and lifecycle actions.
- Author `quickstart.md` for implementation slice sequencing, validation commands, and acceptance verification.
- Update agent context via `.specify/scripts/powershell/update-agent-context.ps1 -AgentType codex`.

## Complexity Tracking

No constitution violations or exceptional complexity requiring justification.
