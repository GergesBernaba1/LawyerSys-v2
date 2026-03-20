namespace LawyerSys.Services;

public enum ServiceResultStatus
{
    Success,
    ValidationFailed,
    Unauthorized,
    Forbidden,
    NotFound,
    Conflict,
    BusinessRuleFailed,
    UnexpectedFailure
}

public sealed class ServiceResult<T>
{
    public ServiceResultStatus Status { get; init; }
    public string? MessageKey { get; init; }
    public object[] MessageArguments { get; init; } = Array.Empty<object>();
    public T? Payload { get; init; }
    public IReadOnlyList<ValidationIssue> ValidationIssues { get; init; } = Array.Empty<ValidationIssue>();

    public bool IsSuccess => Status == ServiceResultStatus.Success;

    public static ServiceResult<T> Success(T payload) =>
        new() { Status = ServiceResultStatus.Success, Payload = payload };

    public static ServiceResult<T> Validation(string messageKey, params ValidationIssue[] issues) =>
        new()
        {
            Status = ServiceResultStatus.ValidationFailed,
            MessageKey = messageKey,
            ValidationIssues = issues
        };

    public static ServiceResult<T> Unauthorized(string messageKey, params object[] args) =>
        new() { Status = ServiceResultStatus.Unauthorized, MessageKey = messageKey, MessageArguments = args };

    public static ServiceResult<T> Forbidden(string messageKey, params object[] args) =>
        new() { Status = ServiceResultStatus.Forbidden, MessageKey = messageKey, MessageArguments = args };

    public static ServiceResult<T> NotFound(string entityName) =>
        new() { Status = ServiceResultStatus.NotFound, MessageKey = "EntityNotFound", MessageArguments = new object[] { entityName } };

    public static ServiceResult<T> Conflict(string messageKey, params object[] args) =>
        new() { Status = ServiceResultStatus.Conflict, MessageKey = messageKey, MessageArguments = args };

    public static ServiceResult<T> BusinessRuleFailure(string messageKey, params object[] args) =>
        new() { Status = ServiceResultStatus.BusinessRuleFailed, MessageKey = messageKey, MessageArguments = args };

    public static ServiceResult<T> Unexpected(string messageKey, params object[] args) =>
        new() { Status = ServiceResultStatus.UnexpectedFailure, MessageKey = messageKey, MessageArguments = args };
}
