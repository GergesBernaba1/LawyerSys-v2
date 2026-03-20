# Phase 0 Research: ClientApp UI Refresh

## Decision 1: Keep the existing frontend stack and modernize through shared UI patterns

- **Decision**: Implement the refresh inside the current Next.js, React, Material UI, Emotion, and i18next stack instead of introducing a new design framework or parallel styling system.
- **Rationale**: The existing ClientApp already uses these dependencies across landing, authentication, and dashboard flows. Reusing them keeps the work parity-safe, minimizes regression risk, and allows the refresh to focus on visual consistency rather than framework migration.
- **Alternatives considered**:
  - Introduce a new component library: rejected because it would expand scope and create migration churn unrelated to the requested UI enhancement.
  - Build one-off page styling only: rejected because it would not solve cross-surface inconsistency.

## Decision 2: Bound the refresh to public entry pages, authentication, shell, and dashboard

- **Decision**: Treat landing, about, contact, login, register, forgot/reset password, main authenticated shell, and dashboard as the primary refresh surfaces.
- **Rationale**: These pages define first impression, navigation consistency, and the highest-visibility operator experience. This scope matches the clarified specification and keeps planning manageable.
- **Alternatives considered**:
  - Refresh the entire ClientApp at once: rejected because it would turn the feature into a full-product redesign with high execution and validation risk.
  - Refresh public pages only: rejected because it would leave the in-app experience visually disconnected from the new entry experience.

## Decision 3: Preserve routes, permissions, and business actions exactly

- **Decision**: The refresh will not change route structure, role visibility rules, backend contracts, or the set of business-critical actions available on in-scope pages.
- **Rationale**: The constitution requires parity-preserving migration and secure access by default. This feature is a presentation improvement, not a workflow redesign.
- **Alternatives considered**:
  - Bundle UX-driven workflow changes with the refresh: rejected because it would mix visual work with behavior changes and complicate acceptance testing.
  - Rework authentication or dashboard actions while refreshing UI: rejected because it would introduce unnecessary security and regression risk.

## Decision 4: Use shared tokens and reusable page patterns as the implementation center

- **Decision**: Drive the refresh through shared theme values, layout primitives, navigation states, page-header patterns, card/table/form treatment, and feedback-state presentation.
- **Rationale**: Shared primitives are the highest-leverage way to produce a cohesive UI refresh across multiple pages while keeping future maintenance costs lower.
- **Alternatives considered**:
  - Restyle each page independently: rejected because it would likely recreate the inconsistency the feature is meant to solve.
  - Limit changes to colors and typography only: rejected because the spec also calls for clearer hierarchy, action emphasis, and state treatment.

## Decision 5: Validate through build checks, Playwright coverage, and bilingual responsive review

- **Decision**: Use the existing frontend build and Playwright setup, then add or adjust end-to-end coverage for the refreshed critical journeys and explicitly review both RTL/LTR and desktop/mobile behavior.
- **Rationale**: This satisfies the constitution's vertical-slice and bilingual UX requirements without inventing a new test harness. The app already includes Playwright coverage for core flows and navigation-related UI.
- **Alternatives considered**:
  - Rely on manual visual review only: rejected because critical UI journeys should remain testable after the refresh.
  - Add backend tests for this feature: rejected because no backend behavior change is planned.
