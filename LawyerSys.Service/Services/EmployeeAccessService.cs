using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services;

public class EmployeeAccessService : IEmployeeAccessService
{
    private readonly LegacyDbContext _legacyDbContext;
    private readonly IUserContext _userContext;

    public EmployeeAccessService(LegacyDbContext legacyDbContext, IUserContext userContext)
    {
        _legacyDbContext = legacyDbContext;
        _userContext = userContext;
    }

    public Task<IList<string>> GetCurrentRolesAsync()
    {
        return _userContext.GetUserRolesAsync();
    }

    public async Task<bool> IsCurrentUserAdminAsync()
    {
        var roles = await GetCurrentRolesAsync();
        return roles.Contains("Admin") || roles.Contains("SuperAdmin");
    }

    public async Task<bool> IsCurrentUserEmployeeOnlyAsync()
    {
        var roles = await GetCurrentRolesAsync();
        return roles.Contains("Employee") && !roles.Contains("Admin") && !roles.Contains("SuperAdmin");
    }

    public async Task<Employee?> GetCurrentEmployeeAsync()
    {
        var userName = _userContext.GetUserName();
        if (string.IsNullOrWhiteSpace(userName))
        {
            return null;
        }

        return await _legacyDbContext.Employees
            .Include(item => item.Users)
            .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);
    }

    public async Task<int?> GetCurrentEmployeeIdAsync()
    {
        var employee = await GetCurrentEmployeeAsync();
        return employee?.id;
    }

    public async Task<int[]> GetAssignedCaseCodesAsync()
    {
        if (!await IsCurrentUserEmployeeOnlyAsync())
        {
            return Array.Empty<int>();
        }

        var employeeId = await GetCurrentEmployeeIdAsync();
        if (!employeeId.HasValue)
        {
            return Array.Empty<int>();
        }

        return await _legacyDbContext.Cases_Employees
            .Where(item => item.Employee_Id == employeeId.Value)
            .Select(item => item.Case_Code)
            .Distinct()
            .ToArrayAsync();
    }

    public async Task<int[]> GetAssignedCustomerIdsAsync()
    {
        if (!await IsCurrentUserEmployeeOnlyAsync())
        {
            return Array.Empty<int>();
        }

        var assignedCaseCodes = await GetAssignedCaseCodesAsync();
        if (assignedCaseCodes.Length == 0)
        {
            return Array.Empty<int>();
        }

        return await _legacyDbContext.Custmors_Cases
            .Where(item => assignedCaseCodes.Contains(item.Case_Id))
            .Select(item => item.Custmors_Id)
            .Distinct()
            .ToArrayAsync();
    }

    public async Task<bool> CanAccessCaseAsync(int caseCode)
    {
        if (await IsCurrentUserAdminAsync())
        {
            return true;
        }

        if (!await IsCurrentUserEmployeeOnlyAsync())
        {
            return false;
        }

        var employeeId = await GetCurrentEmployeeIdAsync();
        if (!employeeId.HasValue)
        {
            return false;
        }

        return await _legacyDbContext.Cases_Employees
            .AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employeeId.Value);
    }

    public async Task<bool> CanAccessCustomerAsync(int customerId)
    {
        if (await IsCurrentUserAdminAsync())
        {
            return true;
        }

        if (!await IsCurrentUserEmployeeOnlyAsync())
        {
            return false;
        }

        var assignedCustomerIds = await GetAssignedCustomerIdsAsync();
        return assignedCustomerIds.Contains(customerId);
    }
}
