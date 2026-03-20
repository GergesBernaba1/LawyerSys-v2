# Controller Migration Inventory

## Purpose

Track controller families as they move from controller-owned business logic to service-owned workflows.

## Initial Priority Slices

| Controller | Priority | Current risk | Notes |
|---|---|---|---|
| `GovernmentsController` | P1 | High | Mixes tenant checks, ownership rules, validation, persistence, and mapping in controller actions |
| `CaseRelationsController` | P1 | High | Mixes access checks, notifications, persistence, and large workflow assembly |
| `CasesController` | P2 | High | Shares case-access logic that should be reusable outside controllers |
| `TrustAccountingController` | P3 | Medium | Heavy business calculations and export workflows make it a strong maintainability candidate |

## Migration Status

| Controller family | Baseline captured | Service extracted | Controller thinned | Parity verified |
|---|---|---|---|---|
| `GovernmentsController` | No | No | No | No |
| `CaseRelationsController` | No | No | No | No |
| `CasesController` | No | No | No | No |
| `TrustAccountingController` | No | No | No | No |

## Completion Notes

- Update this file after each controller-family slice is migrated.
- Record remaining controllers that still contain business-processing responsibilities before closing the feature.
