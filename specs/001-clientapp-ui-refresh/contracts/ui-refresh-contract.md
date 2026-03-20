# UI Contract: ClientApp UI Refresh

## Purpose

Define the visible contract that the refreshed ClientApp surfaces must continue to honor so implementation can modernize presentation without breaking user expectations or downstream validation.

## In-Scope Surfaces

- Public entry: `/`, `/about-us`, `/contact-us`
- Authentication: `/login`, `/register`, `/forgot-password`, `/reset-password`
- Authenticated shell: shared navigation and layout chrome used after sign-in
- Dashboard: `/dashboard`

## Contract Rules

### Route and access continuity

- Existing in-scope routes remain valid.
- Protected routes remain protected by the current authentication and authorization model.
- Public routes remain publicly reachable as they are today.

### Action continuity

- Primary business actions currently available on in-scope pages remain available after refresh.
- Action labels may be clarified, but users must still be able to identify the primary action within one screen view.
- No role-based action becomes newly visible or hidden unless the current shell already enforces that behavior.

### Information continuity

- Existing key page sections remain represented after refresh, even if layout and visual grouping change.
- Dashboard summary information and shortcuts remain present, though their arrangement may change.
- Empty, loading, and error feedback remain visible where current pages already depend on asynchronous data or form submission.

### Locale continuity

- Arabic and English experiences remain supported.
- RTL and LTR alignment must remain coherent for navigation, headings, forms, and action placement.
- Newly introduced UI text must remain localizable through the existing localization approach.

### Responsive continuity

- Desktop and mobile layouts must preserve readable content and tappable primary actions.
- The authenticated shell must not block navigation access on common mobile widths.

## Validation Targets

- Public entry flow: landing to about/contact and primary call-to-action discovery
- Authentication flow: sign-in and password-recovery presentation
- Authenticated flow: shell navigation clarity and dashboard action discoverability
- Cross-cutting review: Arabic/English and desktop/mobile behavior for each representative surface
