# Tasks: ClientApp UI Refresh

**Input**: Design documents from `/specs/001-clientapp-ui-refresh/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-refresh-contract.md`, `quickstart.md`

**Tests**: Include Playwright coverage for changed critical UI journeys because this feature changes public entry, authentication, shell, and dashboard experiences.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the UI refresh baseline, validation entry points, and shared planning references.

- [X] T001 Review and update the implementation notes in `specs/001-clientapp-ui-refresh/quickstart.md`
- [X] T002 Inventory the current shared UI foundation in `LawyerSys/ClientApp/src/theme.ts`, `LawyerSys/ClientApp/app/globals.css`, `LawyerSys/ClientApp/src/providers/Providers.tsx`, and `LawyerSys/ClientApp/src/components/Layout.tsx`
- [X] T003 [P] Create or update a dedicated visual regression journey spec in `LawyerSys/ClientApp/tests/ui-refresh.spec.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared visual system and layout primitives required by all user stories.

**Critical**: No user story work should begin until this phase is complete.

- [X] T004 Refine shared design tokens and component overrides in `LawyerSys/ClientApp/src/theme.ts`
- [X] T005 [P] Align global typography, spacing, and base element styling in `LawyerSys/ClientApp/app/globals.css`
- [X] T006 [P] Update locale-aware theme and provider wiring in `LawyerSys/ClientApp/src/providers/Providers.tsx`
- [X] T007 Implement the refreshed authenticated shell structure and navigation states in `LawyerSys/ClientApp/src/components/Layout.tsx`
- [X] T008 [P] Implement the refreshed public shell primitives in `LawyerSys/ClientApp/src/components/public/PublicSiteShell.tsx`
- [X] T009 Add or revise shared translation keys needed by refreshed common UI in `LawyerSys/ClientApp/src/locales/en/translation.json` and `LawyerSys/ClientApp/src/locales/ar/translation.json`

**Checkpoint**: Shared theme, shell, and localization foundation are ready for story work.

---

## Phase 3: User Story 1 - Navigate a clearer product experience (Priority: P1) MVP

**Goal**: Give visitors and signed-in users a clearer first impression and navigation experience across public entry points and primary navigation.

**Independent Test**: Open landing, about, contact, and authenticated shell surfaces and confirm page hierarchy, active navigation state, and primary actions are obvious without changing any business workflow.

### Tests for User Story 1

- [X] T010 [P] [US1] Add Playwright coverage for public navigation and CTA discoverability in `LawyerSys/ClientApp/tests/ui-refresh.spec.ts`
- [X] T011 [P] [US1] Extend existing sidebar and shell navigation checks in `LawyerSys/ClientApp/tests/sidebar.spec.ts`

### Implementation for User Story 1

- [X] T012 [US1] Refresh the landing page hierarchy and CTA presentation in `LawyerSys/ClientApp/app/page.tsx`
- [X] T013 [P] [US1] Refresh the about page layout and supporting content presentation in `LawyerSys/ClientApp/app/about-us/page.tsx`
- [X] T014 [P] [US1] Refresh the contact page layout, contact cards, and CTA presentation in `LawyerSys/ClientApp/app/contact-us/page.tsx`
- [X] T015 [US1] Align public-shell navigation, header, and footer treatment in `LawyerSys/ClientApp/src/components/public/PublicSiteShell.tsx`
- [X] T016 [US1] Verify route and access continuity for refreshed public pages in `LawyerSys/ClientApp/app/page.tsx`, `LawyerSys/ClientApp/app/about-us/page.tsx`, and `LawyerSys/ClientApp/app/contact-us/page.tsx`

**Checkpoint**: User Story 1 is independently functional and testable as the MVP slice.

---

## Phase 4: User Story 2 - Complete key actions with less visual friction (Priority: P2)

**Goal**: Reduce visual friction on authentication and dashboard task flows while preserving existing routes, actions, and feedback states.

**Independent Test**: Complete representative sign-in and dashboard interaction flows and confirm forms, cards, and feedback states are easier to scan and act on without workflow changes.

### Tests for User Story 2

- [X] T017 [P] [US2] Add Playwright coverage for refreshed authentication journeys in `LawyerSys/ClientApp/tests/ui-refresh.spec.ts`
- [X] T018 [P] [US2] Extend dashboard flow coverage for action discoverability and state handling in `LawyerSys/ClientApp/tests/core-flows.spec.ts`

### Implementation for User Story 2

- [X] T019 [P] [US2] Refresh sign-in presentation and feedback-state styling in `LawyerSys/ClientApp/app/login/page.tsx`
- [X] T020 [P] [US2] Refresh registration form hierarchy and action emphasis in `LawyerSys/ClientApp/app/register/page.tsx`
- [X] T021 [P] [US2] Refresh password recovery flow styling in `LawyerSys/ClientApp/app/forgot-password/page.tsx`
- [X] T022 [P] [US2] Refresh reset-password form layout and validation feedback in `LawyerSys/ClientApp/app/reset-password/page.tsx`
- [X] T023 [US2] Refresh dashboard cards, quick actions, and data grouping in `LawyerSys/ClientApp/app/dashboard/page.tsx`
- [X] T024 [US2] Standardize loading, empty, success, and error state treatment across authentication and dashboard surfaces in `LawyerSys/ClientApp/app/login/page.tsx`, `LawyerSys/ClientApp/app/register/page.tsx`, `LawyerSys/ClientApp/app/forgot-password/page.tsx`, `LawyerSys/ClientApp/app/reset-password/page.tsx`, and `LawyerSys/ClientApp/app/dashboard/page.tsx`

**Checkpoint**: User Story 2 is independently functional and testable without requiring additional module refresh work.

---

## Phase 5: User Story 3 - Trust the product on different devices and languages (Priority: P3)

**Goal**: Preserve usability of the refreshed experience across mobile/desktop widths and Arabic/English directional contexts.

**Independent Test**: Review representative public, authentication, shell, and dashboard surfaces in desktop/mobile and RTL/LTR contexts and confirm no blocked actions, clipped content, or direction errors remain.

### Tests for User Story 3

- [X] T025 [P] [US3] Add responsive viewport coverage for refreshed surfaces in `LawyerSys/ClientApp/tests/ui-refresh.spec.ts`
- [X] T026 [P] [US3] Add bilingual navigation and layout assertions in `LawyerSys/ClientApp/tests/sidebar.spec.ts`

### Implementation for User Story 3

- [X] T027 [US3] Update root layout metadata and shared font/loading behavior for the refreshed bilingual experience in `LawyerSys/ClientApp/app/layout.tsx`
- [X] T028 [US3] Refine locale and direction handling for the refreshed theme in `LawyerSys/ClientApp/src/providers/Providers.tsx` and `LawyerSys/ClientApp/src/theme.ts`
- [X] T029 [US3] Update English and Arabic UI copy needed for refreshed headings, helper text, and feedback states in `LawyerSys/ClientApp/src/locales/en/translation.json` and `LawyerSys/ClientApp/src/locales/ar/translation.json`
- [X] T030 [US3] Resolve responsive layout issues on in-scope public and authenticated pages in `LawyerSys/ClientApp/app/page.tsx`, `LawyerSys/ClientApp/app/login/page.tsx`, `LawyerSys/ClientApp/app/register/page.tsx`, `LawyerSys/ClientApp/app/dashboard/page.tsx`, and `LawyerSys/ClientApp/src/components/Layout.tsx`

**Checkpoint**: All user stories are independently functional with bilingual and responsive validation in place.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize consistency, validation, and delivery-ready documentation across all refreshed surfaces.

- [X] T031 [P] Run final visual consistency cleanup in `LawyerSys/ClientApp/src/theme.ts`, `LawyerSys/ClientApp/app/globals.css`, and `LawyerSys/ClientApp/src/components/Layout.tsx`
- [X] T032 [P] Run and stabilize frontend validation in `LawyerSys/ClientApp/package.json` and `LawyerSys/ClientApp/playwright.config.ts`
- [X] T033 [P] Update feature documentation and review notes in `specs/001-clientapp-ui-refresh/quickstart.md` and `specs/001-clientapp-ui-refresh/tasks.md`
- [X] T034 Run final end-to-end verification for the refresh using `LawyerSys/ClientApp/tests/ui-refresh.spec.ts`, `LawyerSys/ClientApp/tests/core-flows.spec.ts`, and `LawyerSys/ClientApp/tests/sidebar.spec.ts`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies
- **Phase 2: Foundational**: Depends on Phase 1 and blocks all user stories
- **Phase 3: US1**: Depends on Phase 2
- **Phase 4: US2**: Depends on Phase 2; recommended after US1 for smoother visual consistency review
- **Phase 5: US3**: Depends on Phases 3 and 4 because responsive and bilingual fixes must validate the refreshed surfaces
- **Phase 6: Polish**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: No dependency on other user stories after foundational work
- **US2 (P2)**: No hard dependency on US1, but benefits from reusing the shared public/shell patterns introduced earlier
- **US3 (P3)**: Depends on the refreshed surfaces from US1 and US2 being in place before final responsive and bilingual hardening

### Dependency Graph

```text
Phase 1 -> Phase 2 -> US1 -> US3
                  -> US2 -> US3
US1 + US2 -> Phase 6
```

### Parallel Opportunities

- `T003` can run while `T001` and `T002` are being completed
- `T005`, `T006`, `T008`, and `T009` can run in parallel after `T004`
- `T010` and `T011` can run in parallel for US1
- `T013` and `T014` can run in parallel after `T012` establishes the landing direction
- `T017` and `T018` can run in parallel for US2
- `T019`, `T020`, `T021`, and `T022` can run in parallel for authentication pages
- `T025` and `T026` can run in parallel for US3
- `T031`, `T032`, and `T033` can run in parallel before final verification in `T034`

---

## Parallel Example: User Story 1

```text
Task: "T010 [US1] Add Playwright coverage for public navigation and CTA discoverability in LawyerSys/ClientApp/tests/ui-refresh.spec.ts"
Task: "T011 [US1] Extend existing sidebar and shell navigation checks in LawyerSys/ClientApp/tests/sidebar.spec.ts"

Task: "T013 [US1] Refresh the about page layout and supporting content presentation in LawyerSys/ClientApp/app/about-us/page.tsx"
Task: "T014 [US1] Refresh the contact page layout, contact cards, and CTA presentation in LawyerSys/ClientApp/app/contact-us/page.tsx"
```

## Parallel Example: User Story 2

```text
Task: "T019 [US2] Refresh sign-in presentation and feedback-state styling in LawyerSys/ClientApp/app/login/page.tsx"
Task: "T020 [US2] Refresh registration form hierarchy and action emphasis in LawyerSys/ClientApp/app/register/page.tsx"
Task: "T021 [US2] Refresh password recovery flow styling in LawyerSys/ClientApp/app/forgot-password/page.tsx"
Task: "T022 [US2] Refresh reset-password form layout and validation feedback in LawyerSys/ClientApp/app/reset-password/page.tsx"
```

## Parallel Example: User Story 3

```text
Task: "T025 [US3] Add responsive viewport coverage for refreshed surfaces in LawyerSys/ClientApp/tests/ui-refresh.spec.ts"
Task: "T026 [US3] Add bilingual navigation and layout assertions in LawyerSys/ClientApp/tests/sidebar.spec.ts"

Task: "T028 [US3] Refine locale and direction handling for the refreshed theme in LawyerSys/ClientApp/src/providers/Providers.tsx and LawyerSys/ClientApp/src/theme.ts"
Task: "T029 [US3] Update English and Arabic UI copy needed for refreshed headings, helper text, and feedback states in LawyerSys/ClientApp/src/locales/en/translation.json and LawyerSys/ClientApp/src/locales/ar/translation.json"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate public entry pages and primary navigation independently
5. Demo the refreshed first-impression experience before expanding to authenticated task flows

### Incremental Delivery

1. Finish shared theme, shell, and localization foundations
2. Deliver US1 for public entry and navigation clarity
3. Deliver US2 for authentication and dashboard usability
4. Deliver US3 for responsive and bilingual hardening
5. Finish with cross-cutting cleanup and validation

### Parallel Team Strategy

1. One engineer owns shared theme and shell work in Phase 2
2. After Phase 2, a second engineer can take public pages while another handles authentication pages
3. Responsive and bilingual hardening starts once refreshed surfaces are merged and stable

---

## Notes

- All tasks use the required checklist format with task ID, optional parallel marker, optional story label, and exact file paths.
- User stories remain independently testable, with US1 as the recommended MVP scope.
- No backend contract, authorization, or tenant-isolation tasks are included because the plan explicitly bounds this feature to frontend presentation work.

