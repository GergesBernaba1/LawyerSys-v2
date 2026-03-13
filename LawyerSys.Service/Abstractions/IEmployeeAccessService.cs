using LawyerSys.Data.ScaffoldedModels;

namespace LawyerSys.Services;

public interface IEmployeeAccessService
{
    Task<IList<string>> GetCurrentRolesAsync();
    Task<bool> IsCurrentUserAdminAsync();
    Task<bool> IsCurrentUserEmployeeOnlyAsync();
    Task<Employee?> GetCurrentEmployeeAsync();
    Task<int?> GetCurrentEmployeeIdAsync();
    Task<int[]> GetAssignedCaseCodesAsync();
    Task<int[]> GetAssignedCustomerIdsAsync();
    Task<bool> CanAccessCaseAsync(int caseCode);
    Task<bool> CanAccessCustomerAsync(int customerId);
}
