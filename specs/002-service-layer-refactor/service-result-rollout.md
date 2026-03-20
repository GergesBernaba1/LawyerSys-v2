# Service Result Rollout Notes

## Shared Outcome Goals

- Controllers should receive a stable service outcome instead of owning business decisions.
- Services should communicate:
  - success payloads
  - validation failures
  - forbidden and unauthorized decisions
  - missing-entity outcomes
  - conflict and business-rule failures
  - unexpected failures when the workflow cannot complete safely

## Controller Responsibilities

- Keep routing, binding, authorization attributes, and status-code mapping.
- Localize message keys and message arguments into the final response body.
- Avoid direct database, validation, calculation, and side-effect logic.

## Service Responsibilities

- Execute validation, authorization, tenant checks, orchestration, persistence, mapping, and side effects.
- Return payloads or message keys without returning HTTP-specific types.

## Adoption Order

1. Add shared `ServiceResult<T>`, `ValidationIssue`, and `ServiceOperationContext`.
2. Migrate P1 controller families first.
3. Reuse the same result pattern in later controller-family migrations.
