<!--
Sync Impact Report
Version change: unset -> 1.0.0
Modified principles:
- Placeholder Principle 1 -> I. Tenant Isolation Is Mandatory
- Placeholder Principle 2 -> II. Secure And Auditable Access By Default
- Placeholder Principle 3 -> III. Parity-Preserving Migration
- Placeholder Principle 4 -> IV. Testable Vertical Slices
- Placeholder Principle 5 -> V. Bilingual Operator UX
Added sections:
- Platform Constraints & Data Handling
- Delivery Workflow & Quality Gates
Removed sections:
- None
Templates requiring updates:
- updated: .specify/templates/plan-template.md
- updated: .specify/templates/spec-template.md
- updated: .specify/templates/tasks-template.md
- updated: LawyerSys/DOCS/DEVELOPMENT_GUIDE.md
Follow-up TODOs:
- None
-->
# LawyerSys-v2 Constitution

## Core Principles

### I. Tenant Isolation Is Mandatory
Every backend query, mutation, realtime event, file operation, export, and seeded record MUST
resolve against an explicit tenant boundary. Cross-tenant access is allowed only for designated
super-admin capabilities, and those flows MUST apply explicit authorization checks and produce an
auditable record. Server-side tenant context MUST take precedence over client-supplied tenant
identifiers whenever both exist. Rationale: LawyerSys stores legal, billing, and client data for
multiple firms, so tenant leakage is a product-ending failure rather than a recoverable defect.

### II. Secure And Auditable Access By Default
Authentication and authorization changes MUST use the platform's centralized ASP.NET Identity and
JWT pipeline, enforce role and permission checks on both API and UI paths, and preserve audit
coverage for privileged or sensitive actions. Secrets, signing keys, and environment-specific
credentials MUST stay out of source control; demo credentials and seed shortcuts MUST remain
development-only and MUST never become production defaults. Rationale: legal operations, billing,
and trust-accounting actions require defensible access control and traceability.

### III. Parity-Preserving Migration
Changes that replace or extend legacy behavior MUST preserve the intended business workflow, data
meaning, and route/report outcomes unless the feature specification explicitly documents a parity
break and its migration impact. API contract changes between the ASP.NET Core backend and the React
client MUST be coordinated in the same delivery slice or gated behind a safe transition plan.
Rationale: this repository exists to migrate a working legal-office system without silent behavior
loss during the rewrite.

### IV. Testable Vertical Slices
Each feature MUST be implemented as an independently testable slice with the smallest practical
backend, frontend, and data changes needed to prove the user journey. Changes to tenant scoping,
permissions, billing, reporting, data mutation, or critical UI flows MUST add or update automated
tests in the relevant suite (xUnit for backend behavior, Playwright for end-to-end UI coverage, or
both). A feature is not complete until the impacted build, type-check, and automated tests pass.
Rationale: mixed backend/frontend migration work regresses quickly without slice-level proof.

### V. Bilingual Operator UX
User-facing behavior MUST preserve Arabic and English operation, including translatable copy,
direction-aware layout, and clear empty, loading, and error states for office staff and clients.
New UI text MUST be localizable, and any workflow that changes role visibility, tenant visibility,
or document/report output MUST define its locale impact during specification. Rationale:
LawyerSys is already operated in bilingual legal-office contexts, so feature completeness includes
localization correctness, not just functional correctness.

## Platform Constraints & Data Handling

LawyerSys-v2 is governed around an ASP.NET Core 8 backend, a Next.js/React web client in
`LawyerSys/ClientApp`, a Flutter mobile app for iOS/Android, SQL Server persistence through EF Core,
JWT-based authenticated access, and existing audit/logging infrastructure. Feature plans MUST state
which of these surfaces change.

Mobile app features MUST use the same ASP.NET Core Web API endpoints with JWT Bearer token
authentication. Mobile-specific requirements (offline mode, native features, push notifications)
MUST be documented in feature specs and MUST maintain the same tenant isolation, authorization,
and audit requirements as the web client.

Database-first compatibility and migration safety are mandatory. Schema, seed, or data-migration
changes MUST document how existing tenant data, identity records, reports, and demo flows remain
valid after deployment. File uploads, generated PDFs, exports, and notification payloads MUST avoid
cross-tenant leakage and MUST use validated identifiers and storage paths.

## Delivery Workflow & Quality Gates

Every feature spec MUST identify the primary user role, tenant scope, authorization impact,
localization impact, and whether the work preserves or intentionally changes legacy behavior.

Every implementation plan MUST pass a constitution check before design work proceeds. At minimum it
MUST confirm tenant isolation, secure access and audit impact, migration/parity handling, test
coverage, and bilingual UX expectations.

Every task list MUST include the concrete work needed for tests, authorization or audit updates,
localization resources, and seed or migration adjustments when those concerns are affected. Work
that changes a critical user journey MUST not defer its verification tasks to an unspecified later
phase.

Before merge or release, contributors MUST run the impacted validation stack: `dotnet build`,
backend tests under `tests/`, frontend type-check/build in `LawyerSys/ClientApp`, and Playwright
coverage for changed critical UI journeys when applicable.

## Governance

This constitution overrides conflicting local habits and supporting docs. Amendments MUST be made in
the constitution first, include an explicit Sync Impact Report, and update any affected templates or
developer guidance in the same change.

Versioning follows semantic versioning for governance: MAJOR for incompatible principle changes or
principle removals, MINOR for new principles or materially expanded governance, and PATCH for
clarifications that do not change required behavior.

Compliance review is required in three places: feature specification, implementation plan, and code
review or final change summary. Reviews MUST call out any intentional constitution exception and the
approved justification; silent exceptions are non-compliant.

**Version**: 1.0.0 | **Ratified**: 2026-03-13 | **Last Amended**: 2026-03-13
