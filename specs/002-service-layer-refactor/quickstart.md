# Quickstart: Thin Controller Service Refactor

## Goal

Implement and verify one controller-family migration slice while preserving current API behavior.

## Recommended Slice Workflow

1. Capture the current controller behavior with existing tests and add missing parity tests for the selected controller family.
2. Introduce or extend the shared service primitives:
   - `ServiceResult<T>`
   - shared validation issue model
   - reusable test helpers for EF InMemory and fake `IUserContext`
3. Add a domain-oriented service interface and implementation under `LawyerSys.Service\Services\`.
4. Move business logic, authorization checks, tenant checks, calculations, mapping, and side effects from the controller into the new service.
5. Reduce the controller to:
   - route and model binding
   - authorization attributes
   - service invocation
   - HTTP/status-code mapping
   - localized message translation
6. Run backend verification for the migrated slice before moving on to the next controller family.

## Commands

```powershell
dotnet build
dotnet test tests\LawyerSys.Tests\LawyerSys.Tests.csproj
npm --prefix LawyerSys\ClientApp run lint
```

If the migrated slice changes a critical user journey surfaced in the client, also run:

```powershell
npm --prefix LawyerSys\ClientApp run test:e2e
```

## Slice Acceptance Checks

- The controller file no longer contains business validation, EF queries, calculations, or side-effect orchestration for the migrated actions.
- Service tests verify the migrated business rules directly.
- Controller tests verify only HTTP-boundary behavior and parity-critical response mapping.
- Tenant scoping, authorization behavior, notifications, and localized responses remain correct.
- Routes, request shapes, and response DTOs remain unchanged unless explicitly approved.
