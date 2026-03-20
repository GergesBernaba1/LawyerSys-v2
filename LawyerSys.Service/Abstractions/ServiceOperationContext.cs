namespace LawyerSys.Services;

public sealed record ServiceOperationContext(
    string? UserId,
    string? UserName,
    int? TenantId,
    IReadOnlyList<string> Roles,
    string Culture,
    CancellationToken CancellationToken)
{
    public bool IsAuthenticated => !string.IsNullOrWhiteSpace(UserId);

    public bool IsInRole(string role) =>
        Roles.Any(item => string.Equals(item, role, StringComparison.OrdinalIgnoreCase));
}
