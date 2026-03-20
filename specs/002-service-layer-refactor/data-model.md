# Data Model: Thin Controller Service Refactor

## Entity: ControllerRefactorSlice

- **Purpose**: Represents one controller family being migrated from controller-owned business logic to service-owned workflows.
- **Fields**:
  - `ControllerName`: canonical controller identifier
  - `RouteGroup`: primary API route prefix handled by the controller
  - `PrimaryPolicies`: controller/action authorization attributes that must remain at the HTTP boundary
  - `DbContextsUsed`: application and legacy contexts touched by the workflow
  - `ExternalSideEffects`: notifications, audit events, file operations, realtime publishing, or email triggers
  - `ParityStatus`: baseline captured, service extracted, controller thinned, parity verified
- **Relationships**:
  - owns one or more `ServiceWorkflowContract`
  - may emit zero or more `AuditNotificationAction`

## Entity: ServiceWorkflowContract

- **Purpose**: Defines the service-layer entry point that replaces business processing previously embedded in a controller action.
- **Fields**:
  - `InterfaceName`: service interface exposed from `LawyerSys.Service`
  - `OperationName`: business operation invoked by the controller
  - `InputDto`: request data shape consumed by the service
  - `Dependencies`: DbContexts, `IUserContext`, notifications, logging, and other collaborators
  - `ResultType`: `ServiceResult<T>` or `PagedResult<T>` for paginated reads
  - `MessageKeys`: canonical localization keys returned for success and failure cases
- **Relationships**:
  - belongs to one `ControllerRefactorSlice`
  - returns one `ServiceResult`

## Entity: ServiceOperationContext

- **Purpose**: Carries caller identity and request-scoped metadata required for business authorization and tenant-safe processing.
- **Fields**:
  - `UserId`
  - `UserName`
  - `TenantId`
  - `Roles`
  - `Culture`
  - `CancellationToken`
- **Validation rules**:
  - tenant-scoped workflows must not trust client-supplied tenant identifiers over resolved server context
  - privileged operations must include role data sufficient for business authorization checks

## Entity: ServiceResult

- **Purpose**: Standardized non-HTTP outcome returned from service workflows.
- **Fields**:
  - `Status`: success, validation_failed, forbidden, unauthorized, not_found, conflict, business_rule_failed, unexpected_failure
  - `MessageKey`: canonical localization key for the controller to translate
  - `Payload`: DTO returned on success or partial-success scenarios
  - `ValidationIssues`: zero or more validation details
  - `AuditAction`: optional audit metadata for privileged operations
- **Validation rules**:
  - forbidden and unauthorized outcomes must not expose sensitive entity details
  - validation outcomes must provide stable field-level identifiers when the request payload requires correction

## Entity: ValidationIssue

- **Purpose**: Represents one business or input validation problem detected by the service layer.
- **Fields**:
  - `Field`
  - `Code`
  - `MessageKey`
  - `AttemptedValue`
- **Relationships**:
  - belongs to one `ServiceResult`

## Entity: AuditNotificationAction

- **Purpose**: Captures side effects the service may trigger after a successful or rejected business decision.
- **Fields**:
  - `AuditEventType`
  - `NotificationType`
  - `RequiresTenantScope`
  - `ActorUserId`
  - `EntityReference`
- **Validation rules**:
  - super-admin and admin-sensitive mutations must remain auditable
  - tenant-scoped notifications must use validated entity ownership and tenant context

## Lifecycle

### ControllerRefactorSlice

1. `BaselineCaptured`: current controller behavior and tests are documented
2. `ServiceExtracted`: business logic is moved into service workflows
3. `ControllerThinned`: controller retains only routing, binding, authorization attributes, and HTTP mapping
4. `ParityVerified`: service tests and controller-boundary tests confirm the slice matches intended behavior
