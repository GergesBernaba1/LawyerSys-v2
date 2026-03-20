# Contract: Controller-Service Boundary

## Purpose

Define the contract that every migrated controller action and its replacement service workflow must follow during the thin-controller refactor.

## External HTTP Preservation Contract

- Existing controller routes remain unchanged unless a later approved spec explicitly changes them.
- Existing authorization attributes remain on controllers.
- Existing response DTO shapes remain unchanged for successful requests.
- Existing status-code categories remain unchanged for success, validation failure, forbidden access, unauthorized access, missing entities, and business-rule failures.
- Existing bilingual response behavior remains unchanged; user-facing messages continue to be localizable through shared resource keys.

## Internal Service Workflow Contract

Each migrated controller action delegates to a service interface in `LawyerSys.Service` with the following characteristics:

- The service accepts action input DTOs plus a request-scoped operation context derived from `IUserContext`.
- The service performs business validation, authorization checks beyond the route attribute, orchestration, data access, calculations, mapping, and side effects.
- The service returns either:
  - `PagedResult<T>` for pagination-only successful list reads, or
  - `ServiceResult<T>` for any workflow that can succeed or fail by business decision.
- The service does not return `ActionResult`, `IResult`, or localized response objects.

## ServiceResult Mapping Contract

| Service result status | Controller responsibility | HTTP outcome |
|---|---|---|
| `success` | Map payload to normal response body | `200`, `201`, or action-specific success status |
| `validation_failed` | Translate message key and include validation details | `400` |
| `unauthorized` | Translate message key | `401` when action allows anonymous resolution before auth, otherwise controller auth handles it |
| `forbidden` | Translate message key | `403` |
| `not_found` | Translate message key | `404` |
| `conflict` | Translate message key | `409` or existing parity-equivalent failure response |
| `business_rule_failed` | Translate message key | existing parity-equivalent business failure status, typically `400` |
| `unexpected_failure` | Log and map through existing API failure policy | `500` or centralized exception handling path |

## Cross-Cutting Rules

- Controllers remain responsible for:
  - request and route binding
  - authorization attributes
  - passing cancellation tokens
  - converting service outcomes into HTTP responses
  - localizing message keys into response messages
- Services remain responsible for:
  - tenant and ownership enforcement
  - business authorization checks
  - database reads and writes
  - calculations and derived values
  - DTO mapping
  - notifications and audit-worthy side effects

## Verification Expectations

- Every migrated controller family must have service tests covering the extracted business workflow.
- Every migrated controller family must keep a smaller set of controller tests proving HTTP boundary behavior and service outcome mapping.
- No controller migration is complete until parity-critical success and failure scenarios continue to pass.
