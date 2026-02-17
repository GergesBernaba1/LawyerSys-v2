using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface ICustomerService
    {
        Task<IEnumerable<CustomerDto>> GetCustomersAsync();
        Task<PagedResult<CustomerDto>> GetCustomersAsync(int page, int pageSize, string? search);
        Task<CustomerDto?> GetCustomerAsync(int id);
        Task<CustomerProfileDto?> GetCustomerProfileAsync(int id);
        Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto);
        Task<(CustomerDto Customer, (string UserName, string Password) TempCredentials)> CreateCustomerWithUserAsync(CreateCustomerWithUserDto dto);
        Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto);
        Task<bool> DeleteCustomerAsync(int id);
    }
}
