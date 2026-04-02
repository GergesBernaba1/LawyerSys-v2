using LawyerSys.DTOs;

namespace LawyerSys.Services.Landing;

public interface ILandingPageService
{
    Task<LandingPagePublicDto> GetLandingPageAsync(CancellationToken cancellationToken = default);
    Task<LandingPageAdminDto> GetLandingPageAdminAsync(CancellationToken cancellationToken = default);
    Task<LandingPageAdminDto> UpdateLandingPageAsync(UpdateLandingPageRequest request, CancellationToken cancellationToken = default);
}
