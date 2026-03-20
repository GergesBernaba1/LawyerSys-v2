# Research: Thin Controller Service Refactor

## Decision 1: Service-layer pattern

- **Decision**: Use the existing interface-first, domain-oriented service pattern in `LawyerSys.Service` and add new scoped orchestration services by controller area.
- **Rationale**: The repo already uses `IXService`/`XService` pairs and explicit `AddScoped` registration in `Program.cs`. Reusing that structure minimizes churn and keeps the refactor aligned with the current architecture.
- **Alternatives considered**:
  - Add a mediator/CQRS layer for all controller actions: rejected because it introduces a new abstraction stack during a parity-focused refactor.
  - Add a repository layer first: rejected because the existing application already uses EF Core contexts directly in services, and repository introduction would expand scope without solving the thin-controller requirement by itself.

## Decision 2: Business outcome contract

- **Decision**: Introduce a reusable `ServiceResult<T>` pattern for controller-facing workflows and keep `PagedResult<T>` only for pagination payloads.
- **Rationale**: Current services return a mix of DTOs, tuples, nullable values, booleans, and exceptions. A consistent service outcome contract is needed so controllers can stay limited to status-code mapping and localized response construction.
- **Alternatives considered**:
  - Throw exceptions for all business failures: rejected because it makes parity mapping and test coverage noisier across many controllers.
  - Return raw `ActionResult` from services: rejected because it leaks HTTP concerns into the service layer and conflicts with the feature goal.

## Decision 3: Localization boundary

- **Decision**: Services return canonical outcome/message keys and structured failure metadata; controllers remain responsible for converting those keys into localized HTTP responses.
- **Rationale**: The constitution requires bilingual behavior, and the sampled controllers currently localize messages directly. Keeping localization at the API edge preserves operator UX while allowing service logic to stay reusable outside controllers.
- **Alternatives considered**:
  - Inject `IStringLocalizer` into every new service and return localized strings: rejected because it couples business logic to presentation concerns and makes service reuse harder.
  - Return only status enums with no message keys: rejected because localized validation and failure responses still need stable translation hooks.

## Decision 4: Authorization, tenant isolation, and side effects

- **Decision**: Keep authorization attributes on controllers, but move business authorization, tenant/ownership checks, notification dispatch, and audit-worthy decisions into services.
- **Rationale**: Current controllers such as `GovernmentsController` and `CaseRelationsController` mix declarative authorization with inline ownership rules and side effects. Centralizing those rules in services reduces regression risk and improves reuse.
- **Alternatives considered**:
  - Keep inline business authorization inside controllers: rejected because it preserves the existing problem and prevents clean separation of concerns.
  - Move authorization attributes into services: rejected because route-level authorization belongs at the HTTP boundary in ASP.NET Core.

## Decision 5: Test strategy

- **Decision**: Add service-first behavior tests using EF Core InMemory and keep a thinner layer of controller tests focused on HTTP mapping, authorization outcomes, and response shaping.
- **Rationale**: Existing tests are heavily controller-first. That is useful for parity checks, but a system-wide refactor needs direct service coverage so business rules can be validated without routing and `ActionResult` noise.
- **Alternatives considered**:
  - Keep all tests controller-first: rejected because it slows down migration and makes service extraction harder to validate precisely.
  - Convert entirely to mocks-only unit tests: rejected because many workflows depend on EF query behavior, relationship loading, and persistence semantics already covered effectively by InMemory contexts.

## Decision 6: Delivery sequence

- **Decision**: Deliver the refactor incrementally by controller family, starting with controllers that currently embed the most authorization, tenant-scoping, validation, or side-effect logic.
- **Rationale**: The feature scope is system-wide, but the constitution requires independently testable slices. Migrating by controller family preserves momentum while keeping each change reviewable and verifiable.
- **Alternatives considered**:
  - Big-bang refactor of all controllers at once: rejected because the parity and regression risk would be too high.
  - Restrict the change to a single controller: rejected because the clarified feature scope explicitly covers all controllers in the system.
