using LawyerSys.DTOs;

namespace LawyerSys.Services.Administration;

public interface IAdministrationService
{
    Task<AdministrationOverviewDto> GetOverviewAsync(CancellationToken cancellationToken = default);
}
