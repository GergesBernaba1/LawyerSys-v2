namespace LawyerSys.Services;

public interface IUserContext
{
    string? GetUserId();
    string? GetUserName();
    string? GetEmail();
    int? GetTenantId();
    Task<bool> IsInRoleAsync(string role);
    Task<IList<string>> GetUserRolesAsync();
}
