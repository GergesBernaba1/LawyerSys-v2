namespace LawyerSys.Services;

public sealed class ValidationIssue
{
    public string Field { get; init; } = string.Empty;
    public string Code { get; init; } = string.Empty;
    public string MessageKey { get; init; } = string.Empty;
    public object? AttemptedValue { get; init; }
}
