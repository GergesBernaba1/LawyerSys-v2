using LawyerSys.DTOs;

namespace LawyerSys.Services.Audit;

public interface IAuditLogsService
{
    Task<PagedResult<AuditLogDto>> GetAuditLogsAsync(int page, int pageSize, string? search, string? entityName, string? action, CancellationToken cancellationToken = default);
}
