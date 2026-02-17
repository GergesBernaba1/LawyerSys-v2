using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface IEmployeeService
    {
        Task<IEnumerable<EmployeeDto>> GetEmployeesAsync();
        Task<PagedResult<EmployeeDto>> GetEmployeesAsync(int page, int pageSize, string? search);
        Task<EmployeeDto?> GetEmployeeAsync(int id);
        Task<EmployeeDto> CreateEmployeeAsync(CreateEmployeeDto dto);
        Task<(EmployeeDto Employee, (string UserName, string Password) TempCredentials)> CreateEmployeeWithUserAsync(CreateEmployeeWithUserDto dto);
        Task<EmployeeDto> UpdateEmployeeAsync(int id, UpdateEmployeeDto dto);
        Task<bool> DeleteEmployeeAsync(int id);
    }
}
