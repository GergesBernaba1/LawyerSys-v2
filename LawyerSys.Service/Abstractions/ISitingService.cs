using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface ISitingService
    {
        // Sitings CRUD
        Task<IEnumerable<SitingDto>> GetSitingsAsync(string? search = null);
        Task<PagedResult<SitingDto>> GetSitingsAsync(int page, int pageSize, string? search);
        Task<SitingDto?> GetSitingAsync(int id);
        Task<SitingDto> CreateSitingAsync(CreateSitingDto dto);
        Task<SitingDto> UpdateSitingAsync(int id, UpdateSitingDto dto);
        Task<bool> DeleteSitingAsync(int id);
    }
}
