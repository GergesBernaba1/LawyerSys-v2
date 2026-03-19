# Data Model: ClientApp UI Refresh

This feature does not introduce new persistent database entities. The design work still relies on a small set of conceptual UI entities so implementation and testing stay consistent.

## Entity: Refresh Surface

- **Purpose**: Represents an in-scope page or layout surface that must adopt the refreshed design language.
- **Fields**:
  - `name`: canonical surface name
  - `category`: public-entry, authentication, authenticated-shell, dashboard, shared-pattern
  - `priority`: rollout priority aligned to user stories
  - `mustPreserveActions`: list of existing user actions that cannot disappear
  - `mustPreserveData`: list of visible information groups that must remain available
- **Relationships**:
  - Uses one or more `Shared UI Pattern` entities
  - Supports one or more `Locale Variant` entities

## Entity: Shared UI Pattern

- **Purpose**: Represents a reusable presentation pattern applied across refreshed surfaces.
- **Fields**:
  - `name`: page header, navigation item, action button, card, table wrapper, form field, feedback state, empty state
  - `visualRules`: hierarchy, spacing, emphasis, density, state treatment
  - `interactionStates`: default, hover, focus, disabled, loading, success, empty, error
  - `applicability`: surfaces where the pattern must remain consistent
- **Validation Rules**:
  - Must be applicable across more than one in-scope surface
  - Must preserve current action discoverability and usability

## Entity: Locale Variant

- **Purpose**: Captures the language and direction requirements of the refreshed UI.
- **Fields**:
  - `locale`: Arabic or English
  - `direction`: RTL or LTR
  - `textSource`: existing localizable copy resource
  - `layoutAdjustments`: alignment and directional behaviors required for that locale
- **Validation Rules**:
  - Every refreshed surface must support both locale variants
  - Direction-aware alignment must not hide or reorder primary actions incorrectly

## Entity: Feedback State

- **Purpose**: Defines the user-visible status handling used on refreshed surfaces.
- **Fields**:
  - `type`: loading, success, empty, validation-error, retrieval-error
  - `messageIntent`: informative, cautionary, recoverable-error
  - `nextAction`: retry, navigate, submit, dismiss, none
  - `visibilityRule`: when the state appears and what content it replaces or overlays
- **Validation Rules**:
  - Each in-scope surface with asynchronous or empty content must define at least the relevant loading, empty, and error states
  - Feedback must not block the user's next valid action without explanation

## State Transitions

### Refresh Surface lifecycle

1. `Current` -> existing presentation before the feature
2. `Refreshed` -> updated to the new design language with preserved actions and data
3. `Verified` -> passes responsive, bilingual, and critical-journey validation

### Feedback State lifecycle

1. `Idle` -> no transient message shown
2. `Loading` -> action or retrieval in progress
3. `Resolved` -> success or content-ready state
4. `Recoverable Failure` -> validation or retrieval issue with visible next step
