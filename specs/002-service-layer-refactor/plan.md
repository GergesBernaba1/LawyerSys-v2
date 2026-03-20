# Implementation Plan: Thin Controller Service Refactor

**Branch**: `[002-service-layer-refactor]` | **Date**: 2026-03-20 | **Spec**: [D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\spec.md](D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\spec.md)
**Input**: Feature specification from `D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\spec.md`

## Summary

Refactor the ASP.NET Core backend so controllers across the system retain only HTTP concerns while business rules, validation, orchestration, data access, calculations, mapping, and side effects move into domain-focused services in `LawyerSys.Service`. Preserve existing API routes, authorization attributes, bilingual responses, and business behavior while introducing a consistent service outcome contract and a controller-to-service migration pattern that can be applied incrementally across controller families.

## Technical Context

**Language/Version**: C# 12 on .NET 8, TypeScript 5.x for the existing client context  
**Primary Dependencies**: ASP.NET Core Web API, EF Core 8, ASP.NET Identity, JWT Bearer auth, Serilog, xUnit, Moq, Next.js 14.2, React 18  
**Storage**: PostgreSQL via `ApplicationDbContext` and `LegacyDbContext` in `LawyerSys.Domain`/`LawyerSys.Infrastructure`  
**Testing**: xUnit with EF Core InMemory for backend behavior tests; Playwright available for client-critical flows  
**Target Platform**: Multi-tenant web application on ASP.NET Core 8 with a Next.js client  
**Project Type**: Web application with backend API, service layer, infrastructure, domain, and frontend client  
**Performance Goals**: Preserve current endpoint responsiveness with no material regression from the refactor; keep pagination, query scope, and side-effect behavior equivalent to current production behavior  
**Constraints**: Preserve tenant isolation, existing routes and status semantics, centralized auth policies, bilingual messaging, and legacy/business parity while avoiding broad schema changes  
**Scale/Scope**: System-wide backend controller refactor across dozens of controllers and their related workflows, delivered as incremental controller-family slices

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Gate Review

- **I. Tenant Isolation Is Mandatory**: Pass. The plan explicitly moves tenant and ownership checks into reusable services instead of leaving them scattered in controllers, with server-side `IUserContext` and database-backed tenant resolution remaining authoritative.
- **II. Secure And Auditable Access By Default**: Pass. Authorization attributes remain on controllers; service workflows will own business-level authorization, auditable admin/super-admin decisions, and side-effect coordination without weakening the Identity/JWT pipeline.
- **III. Parity-Preserving Migration**: Pass. Preserving current endpoint routes, status codes, localization behavior, and business outcomes is the primary delivery constraint for every migrated slice.
- **IV. Testable Vertical Slices**: Pass. The implementation strategy is incremental by controller family with service-first behavior tests and a reduced controller-boundary test layer to prove each slice independently.
- **V. Bilingual Operator UX**: Pass. Controllers remain responsible for HTTP response translation and localized message rendering, while services return canonical message keys and structured outcomes.

### Post-Design Gate Review

- **Tenant Isolation**: Pass. Design introduces explicit `ServiceOperationContext` and reusable access evaluators for tenant-owned identity data and legacy case-access rules.
- **Secure Access And Auditability**: Pass. Design keeps declarative authorization in controllers and centralizes business authorization, notification triggers, and audit-worthy decisions in services.
- **Parity-Preserving Migration**: Pass. Contracts and quickstart require route/response parity validation for each migrated controller slice before broad rollout continues.
- **Testable Vertical Slices**: Pass. Data model, contracts, and quickstart define per-slice migration, service tests with EF InMemory, and controller-boundary assertions.
- **Bilingual Operator UX**: Pass. Design preserves localized API responses by translating service message keys at the controller edge; no new unlocalized user-facing text is introduced by the refactor.

## Project Structure

### Documentation (this feature)

```text
D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\specs\002-service-layer-refactor\
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts\
|   `-- controller-service-contract.md
`-- tasks.md
```

### Source Code (repository root)

```text
D:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2\
|-- LawyerSys\
|   |-- Controllers\
|   |-- Extensions\
|   |-- Program.cs
|   `-- LawyerSys.csproj
|-- LawyerSys.Service\
|   |-- Abstractions\
|   |-- DTOs\
|   |-- Resources\
|   `-- Services\
|-- LawyerSys.Domain\
|   |-- Data\
|   `-- ScaffoldedModels\
|-- LawyerSys.Infrastructure\
|   `-- Data\
`-- tests\
    `-- LawyerSys.Tests\
```

**Structure Decision**: Keep the existing layered backend structure. Controllers remain in `LawyerSys/Controllers`, reusable business orchestration and result contracts live in `LawyerSys.Service`, persistent models remain in `LawyerSys.Domain`, database configuration stays in `LawyerSys.Infrastructure`, and backend parity tests stay in `tests/LawyerSys.Tests`.

## Phase 0: Research Summary

Research resolved the implementation unknowns in `research.md`:

- Use interface-first, domain-oriented services rather than adding a mediator or repository layer.
- Introduce a reusable `ServiceResult<T>` outcome model for controller-facing business workflows while keeping `PagedResult<T>` for pagination.
- Preserve localization at the controller edge by returning canonical message keys from services.
- Move notifications, tenant/ownership checks, and business authorization into services.
- Shift most behavioral verification from controller-first tests to service tests while retaining thin controller boundary tests.

## Phase 1: Design Summary

- Define a `ControllerRefactorSlice` model to migrate controller families incrementally.
- Define `ServiceOperationContext`, `ServiceResult<T>`, and `ValidationIssue` as shared service-layer concepts.
- Document the HTTP preservation contract and service boundary contract in `contracts/controller-service-contract.md`.
- Provide a quickstart workflow for adding one migration slice, testing it, and validating parity before continuing.

## Implementation Strategy

1. Establish the shared service primitives and test helpers once.
2. Migrate high-risk controller families first where tenant, notification, or authorization logic currently lives in controllers.
3. For each controller family, add service tests, extract business logic into domain-oriented services, thin the controller to HTTP-only behavior, and preserve route/response contracts.
4. Keep frontend changes out of scope unless a contract break is explicitly approved.
5. Use parity verification after each slice before moving to the next family.

## Complexity Tracking

No constitution violations or exceptional complexity waivers are required for this plan.
