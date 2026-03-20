using LawyerSys.DTOs;

namespace LawyerSys.Services.Governments;

public interface IGovernmentsService
{
    Task<IReadOnlyList<LocationCatalogCountryDto>> GetLocationCatalogAsync(int? countryId, CancellationToken cancellationToken = default);
    Task<ServiceResult<LocationCatalogCityDto>> CreateCityAsync(UpdateLocationCityDto dto, CancellationToken cancellationToken = default);
    Task<ServiceResult<LocationCatalogCityDto>> UpdateCityAsync(int id, UpdateLocationCityDto dto, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> DeleteCityAsync(int id, CancellationToken cancellationToken = default);
    Task<object> GetGovernmentsAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default);
    Task<ServiceResult<GovernamentDto>> GetGovernmentAsync(int id, CancellationToken cancellationToken = default);
    Task<ServiceResult<GovernamentDto>> CreateGovernmentAsync(CreateGovernamentDto dto, CancellationToken cancellationToken = default);
    Task<ServiceResult<GovernamentDto>> UpdateGovernmentAsync(int id, CreateGovernamentDto dto, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> DeleteGovernmentAsync(int id, CancellationToken cancellationToken = default);
}
