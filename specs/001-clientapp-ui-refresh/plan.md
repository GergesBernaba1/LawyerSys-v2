# Implementation Plan: ClientApp UI Refresh

**Branch**: `[001-clientapp-ui-refresh]` | **Date**: 2026-03-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-clientapp-ui-refresh/spec.md`

## Summary

Refresh the ClientApp public entry pages plus the main authenticated shell and dashboard so the product feels noticeably more modern while staying recognizable to current users. The implementation will stay inside the existing Next.js 14, React 18, Material UI, and i18next frontend stack, concentrate changes in shared layout and visual patterns, and verify the result with frontend build checks plus Playwright coverage for critical UI journeys.

## Technical Context

**Language/Version**: TypeScript 5.x, React 18, Next.js 14.2, CSS via existing global styles and Material UI theming  
**Primary Dependencies**: Next.js, React, Material UI, Emotion, i18next, axios  
**Storage**: No new persistence; existing ASP.NET Core backend APIs and current browser session state only  
**Testing**: Frontend build/type-check, existing Playwright end-to-end suite in `LawyerSys/ClientApp/tests`, targeted manual bilingual responsive review  
**Target Platform**: Web application for modern desktop and mobile browsers used by LawyerSys operators and visitors  
**Project Type**: Web application with ASP.NET Core backend and Next.js frontend  
**Performance Goals**: Preserve current page responsiveness; no added blocking UI behavior on landing, authentication, shell, or dashboard flows; maintain smooth first-view interaction on standard office hardware  
**Constraints**: No tenant-boundary changes, no permission changes, no backend contract changes required for the refresh, bilingual Arabic/English support, RTL/LTR correctness, preserve current business-critical actions, keep deeper modules out of scope unless shell continuity requires small visual alignment  
**Scale/Scope**: Public entry pages, authentication pages, main authenticated shell, dashboard, and shared UI primitives that influence those surfaces

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Tenant Isolation Is Mandatory**: Pass. Work is frontend-only styling and layout refinement on existing surfaces. No tenant-scoping logic or cross-tenant data paths are introduced.
- **II. Secure And Auditable Access By Default**: Pass. The refresh preserves current authentication, authorization, and privileged action paths. No secrets, auth flow changes, or audit exceptions are planned.
- **III. Parity-Preserving Migration**: Pass. The plan explicitly preserves business-critical actions, existing route outcomes, and current backend contracts while improving presentation.
- **IV. Testable Vertical Slices**: Pass. Delivery is a UI-focused vertical slice covering landing/auth/shell/dashboard with Playwright validation for changed critical journeys and frontend build verification.
- **V. Bilingual Operator UX**: Pass. Arabic/English copy, direction-aware layout, and empty/loading/error states are in scope and called out in the spec and plan.

## Project Structure

### Documentation (this feature)

```text
specs/001-clientapp-ui-refresh/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- ui-refresh-contract.md
`-- tasks.md
```

### Source Code (repository root)

```text
LawyerSys/
|-- ClientApp/
|   |-- app/
|   |   |-- layout.tsx
|   |   |-- page.tsx
|   |   |-- login/
|   |   |-- register/
|   |   |-- forgot-password/
|   |   |-- reset-password/
|   |   |-- dashboard/
|   |   |-- about-us/
|   |   `-- contact-us/
|   |-- src/
|   |   |-- components/
|   |   |-- providers/
|   |   |-- lib/
|   |   `-- theme/
|   |-- tests/
|   |-- package.json
|   `-- playwright.config.ts
|-- Controllers/
|-- Services/
`-- Resources/

tests/
`-- LawyerSys.Tests/
```

**Structure Decision**: Use the existing ASP.NET Core plus Next.js web-application structure. The feature is implemented entirely within `LawyerSys/ClientApp`, while backend and xUnit areas remain unchanged unless validation support reveals a narrow dependency.

## Phase 0: Research

See [research.md](./research.md) for the resolved implementation decisions covering design-system reuse, scope boundaries, bilingual/RTL handling, and validation strategy.

## Phase 1: Design & Contracts

- Document the conceptual UI entities and their rules in [data-model.md](./data-model.md).
- Define the expected UI behavior and preserved interaction contract in [contracts/ui-refresh-contract.md](./contracts/ui-refresh-contract.md).
- Capture implementation and validation steps in [quickstart.md](./quickstart.md).
- Refresh agent context after artifact generation so downstream implementation inherits the current plan context.

## Post-Design Constitution Check

- **I. Tenant Isolation Is Mandatory**: Pass. Design artifacts keep the refresh restricted to presentation and shared UI patterns with no tenant-data changes.
- **II. Secure And Auditable Access By Default**: Pass. Contracts require current protected routes and action visibility to remain intact.
- **III. Parity-Preserving Migration**: Pass. The contract and quickstart both require route continuity and unchanged business actions across refreshed surfaces.
- **IV. Testable Vertical Slices**: Pass. Quickstart includes build and Playwright validation for the changed user journeys.
- **V. Bilingual Operator UX**: Pass. Data model and UI contract both include locale variant and directional behavior requirements.

## Complexity Tracking

No constitution violations or justified exceptions are required for this feature.
