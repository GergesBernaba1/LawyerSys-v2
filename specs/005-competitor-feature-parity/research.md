# Phase 0 Research: Competitor Feature Parity and Improvement

## Decision 1: Tenant-scoped capability catalog with explicit coverage states
- Decision: Store competitor capabilities per tenant business context, while allowing shared reference taxonomy (category set) and tenant-local coverage assessment states (`covered`, `partially_covered`, `missing`).
- Rationale: Keeps tenant isolation intact while enabling consistent comparison language across firms.
- Alternatives considered:
  - Fully global catalog with global status values (rejected: risks tenant leakage and inaccurate tenant-specific prioritization).
  - Fully tenant-independent free-form tags (rejected: weak comparability and noisy prioritization).

## Decision 2: Fine-grained RBAC + auditable updates
- Decision: Enforce role-specific permissions for Admin, Partner, Operations, Analyst, and Viewer, and require mandatory change-log records for roadmap edits.
- Rationale: Prioritization decisions are sensitive and need both control and traceability for legal-office governance.
- Alternatives considered:
  - Admin-only ownership (rejected: operational bottleneck).
  - Basic two-role split (rejected: too coarse for review/accountability needs).

## Decision 3: Completion requires release + measured outcome success
- Decision: Roadmap items move to `completed` only after deployment and successful KPI validation within a defined review window.
- Rationale: Prevents release-only completion inflation and keeps roadmap truth aligned with business outcomes.
- Alternatives considered:
  - Release-only completion (rejected: no value validation).
  - Manual approval without KPI proof (rejected: subjective and inconsistent).

## Decision 4: Weekly evidence refresh and priority recalculation
- Decision: Run weekly refresh of competitor evidence and ranking recalculation as baseline cadence.
- Rationale: Balances responsiveness against operational cost and supports steady roadmap updates.
- Alternatives considered:
  - Monthly refresh (rejected: slower response to competitor movement).
  - Event-only refresh (rejected: unstable and inconsistent governance rhythm).

## Decision 5: Saudi-first compliance baseline
- Decision: Use Saudi legal/regulatory requirements as the primary compliance baseline for parity and enhancement prioritization.
- Rationale: Matches current market positioning and avoids early over-expansion in compliance scope.
- Alternatives considered:
  - GCC-wide baseline now (rejected: larger scope and higher coordination cost).
  - Global-generic baseline (rejected: less actionable for current target market).

## Resolved Technical Context Clarifications

- No remaining `NEEDS CLARIFICATION` markers for this planning phase.
- Integration pattern: Backend API contracts exposed from ASP.NET Core controllers and consumed by Next.js client services.
- Testing pattern: Backend unit/integration coverage + Playwright flow checks for role-based visibility and workflow completion states.
