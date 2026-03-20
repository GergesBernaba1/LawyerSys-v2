using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface ICourtService
    {
        // Courts CRUD
        Task<IEnumerable<CourtDto>> GetCourtsAsync(string? search = null);
        Task<PagedResult<CourtDto>> GetCourtsAsync(int page, int pageSize, string? search);
        Task<CourtDto?> GetCourtAsync(int id);
        Task<CourtDto> CreateCourtAsync(CreateCourtDto dto);
        Task<CourtDto> UpdateCourtAsync(int id, UpdateCourtDto dto);
        Task<bool> DeleteCourtAsync(int id);

        // Government options based on user country
        Task<IEnumerable<GovernamentDto>> GetGovernmentOptionsAsync();
        Task<bool> CanUseGovernmentAsync(int governmentId);
    }
}
