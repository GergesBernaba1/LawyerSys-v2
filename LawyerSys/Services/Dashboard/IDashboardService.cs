using LawyerSys.DTOs;

namespace LawyerSys.Services.Dashboard;

public interface IDashboardService
{
    Task<DashboardAnalyticsDto> GetAnalyticsAsync(CancellationToken cancellationToken = default);
}
