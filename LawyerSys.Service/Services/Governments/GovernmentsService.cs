using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Governments;

public sealed class GovernmentsService : IGovernmentsService
{
    private readonly LegacyDbContext _legacyDbContext;
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IServiceOperationContextFactory _operationContextFactory;

    public GovernmentsService(
        LegacyDbContext legacyDbContext,
        ApplicationDbContext applicationDbContext,
        IServiceOperationContextFactory operationContextFactory)
    {
        _legacyDbContext = legacyDbContext;
        _applicationDbContext = applicationDbContext;
        _operationContextFactory = operationContextFactory;
    }

    public async Task<IReadOnlyList<LocationCatalogCountryDto>> GetLocationCatalogAsync(int? countryId, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var isSuperAdmin = operationContext.IsInRole("SuperAdmin");
        var effectiveCountryId = countryId;
        var currentTenantId = operationContext.TenantId;

        if (!isSuperAdmin)
        {
            if (string.IsNullOrWhiteSpace(operationContext.UserId))
                return Array.Empty<LocationCatalogCountryDto>();

            var currentUser = await _applicationDbContext.Users.AsNoTracking()
                .SingleOrDefaultAsync(user => user.Id == operationContext.UserId, cancellationToken);
            effectiveCountryId = currentUser?.CountryId;
            currentTenantId ??= currentUser?.TenantId;

            if (effectiveCountryId is null or <= 0)
                return Array.Empty<LocationCatalogCountryDto>();
        }

        IQueryable<Country> query = _applicationDbContext.Countries.AsNoTracking().Include(item => item.Cities);
        if (effectiveCountryId.HasValue && effectiveCountryId.Value > 0)
            query = query.Where(item => item.Id == effectiveCountryId.Value);

        var countries = await query
            .OrderBy(item => item.Name)
            .Select(country => new LocationCatalogCountryDto
            {
                Id = country.Id,
                NameEn = country.Name,
                NameAr = country.NameAr,
                CityCount = country.Cities.Count,
                Cities = country.Cities.OrderBy(city => city.Name).Select(city => new LocationCatalogCityDto
                {
                    Id = city.Id,
                    CountryId = city.CountryId,
                    NameEn = city.Name,
                    NameAr = city.NameAr,
                    IsTenantOwned = city.TenantId.HasValue && city.CreatedByUserId != null,
                    CanEdit = isSuperAdmin || (currentTenantId.HasValue && !string.IsNullOrWhiteSpace(operationContext.UserId) && city.TenantId == currentTenantId.Value && city.CreatedByUserId == operationContext.UserId),
                    CanDelete = isSuperAdmin || (currentTenantId.HasValue && !string.IsNullOrWhiteSpace(operationContext.UserId) && city.TenantId == currentTenantId.Value && city.CreatedByUserId == operationContext.UserId)
                }).ToList()
            })
            .ToListAsync(cancellationToken);

        return countries;
    }

    public async Task<ServiceResult<LocationCatalogCityDto>> CreateCityAsync(UpdateLocationCityDto dto, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var nameEn = (dto.NameEn ?? string.Empty).Trim();
        var nameAr = (dto.NameAr ?? string.Empty).Trim();
        if (dto.CountryId <= 0)
            return ServiceResult<LocationCatalogCityDto>.Validation("CountryRequired", BuildIssue(nameof(dto.CountryId), "required", "CountryRequired", dto.CountryId));
        if (string.IsNullOrWhiteSpace(nameEn))
            return ServiceResult<LocationCatalogCityDto>.Validation("EnglishCityNameRequired", BuildIssue(nameof(dto.NameEn), "required", "EnglishCityNameRequired", dto.NameEn));
        if (string.IsNullOrWhiteSpace(nameAr))
            return ServiceResult<LocationCatalogCityDto>.Validation("ArabicCityNameRequired", BuildIssue(nameof(dto.NameAr), "required", "ArabicCityNameRequired", dto.NameAr));

        var isSuperAdmin = operationContext.IsInRole("SuperAdmin");
        var currentUser = await GetCurrentUserAsync(operationContext, cancellationToken);
        if (!isSuperAdmin)
        {
            if (currentUser == null)
                return ServiceResult<LocationCatalogCityDto>.Unauthorized("UserNotFound");
            if (currentUser.CountryId is null or <= 0 || currentUser.CountryId.Value != dto.CountryId)
                return ServiceResult<LocationCatalogCityDto>.Forbidden("OnlyAddCitiesToProfileCountry");
            if (currentUser.TenantId <= 0)
                return ServiceResult<LocationCatalogCityDto>.Validation("TenantNotFoundForUser", BuildIssue("TenantId", "missing", "TenantNotFoundForUser", currentUser.TenantId));
        }

        if (!await _applicationDbContext.Countries.AnyAsync(item => item.Id == dto.CountryId, cancellationToken))
            return ServiceResult<LocationCatalogCityDto>.Validation("CountryNotFound", BuildIssue(nameof(dto.CountryId), "not_found", "CountryNotFound", dto.CountryId));

        var duplicateExists = await _applicationDbContext.Cities.AnyAsync(item => item.CountryId == dto.CountryId && item.Name.ToLower() == nameEn.ToLower(), cancellationToken);
        if (duplicateExists)
            return ServiceResult<LocationCatalogCityDto>.Conflict("CityNameExists");

        var city = new City
        {
            CountryId = dto.CountryId,
            Name = nameEn,
            NameAr = nameAr,
            TenantId = isSuperAdmin ? null : currentUser?.TenantId,
            CreatedByUserId = isSuperAdmin ? null : currentUser?.Id
        };

        _applicationDbContext.Cities.Add(city);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<LocationCatalogCityDto>.Success(MapCity(city, true, true));
    }

    public async Task<ServiceResult<LocationCatalogCityDto>> UpdateCityAsync(int id, UpdateLocationCityDto dto, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var city = await _applicationDbContext.Cities.FindAsync(new object[] { id }, cancellationToken);
        if (city == null)
            return ServiceResult<LocationCatalogCityDto>.NotFound("City");

        var nameEn = (dto.NameEn ?? string.Empty).Trim();
        var nameAr = (dto.NameAr ?? string.Empty).Trim();
        if (dto.CountryId <= 0)
            return ServiceResult<LocationCatalogCityDto>.Validation("CountryRequired", BuildIssue(nameof(dto.CountryId), "required", "CountryRequired", dto.CountryId));
        if (string.IsNullOrWhiteSpace(nameEn))
            return ServiceResult<LocationCatalogCityDto>.Validation("EnglishCityNameRequired", BuildIssue(nameof(dto.NameEn), "required", "EnglishCityNameRequired", dto.NameEn));
        if (string.IsNullOrWhiteSpace(nameAr))
            return ServiceResult<LocationCatalogCityDto>.Validation("ArabicCityNameRequired", BuildIssue(nameof(dto.NameAr), "required", "ArabicCityNameRequired", dto.NameAr));

        var isSuperAdmin = operationContext.IsInRole("SuperAdmin");
        var currentUser = await GetCurrentUserAsync(operationContext, cancellationToken);
        if (!isSuperAdmin)
        {
            if (currentUser == null)
                return ServiceResult<LocationCatalogCityDto>.Unauthorized("UserNotFound");
            if (city.TenantId != currentUser.TenantId || city.CreatedByUserId != currentUser.Id)
                return ServiceResult<LocationCatalogCityDto>.Forbidden("OnlyUpdateTenantCities");
            if (currentUser.CountryId is null or <= 0 || currentUser.CountryId.Value != dto.CountryId)
                return ServiceResult<LocationCatalogCityDto>.Forbidden("OnlyMoveCitiesInsideProfileCountry");
        }

        if (!await _applicationDbContext.Countries.AnyAsync(item => item.Id == dto.CountryId, cancellationToken))
            return ServiceResult<LocationCatalogCityDto>.Validation("CountryNotFound", BuildIssue(nameof(dto.CountryId), "not_found", "CountryNotFound", dto.CountryId));

        var duplicateExists = await _applicationDbContext.Cities.AnyAsync(item => item.Id != id && item.CountryId == dto.CountryId && item.Name.ToLower() == nameEn.ToLower(), cancellationToken);
        if (duplicateExists)
            return ServiceResult<LocationCatalogCityDto>.Conflict("CityNameExists");

        city.CountryId = dto.CountryId;
        city.Name = nameEn;
        city.NameAr = nameAr;
        await _applicationDbContext.SaveChangesAsync(cancellationToken);

        var canDelete = isSuperAdmin || (currentUser != null && city.TenantId == currentUser.TenantId && city.CreatedByUserId == currentUser.Id);
        return ServiceResult<LocationCatalogCityDto>.Success(MapCity(city, true, canDelete));
    }

    public async Task<ServiceResult<bool>> DeleteCityAsync(int id, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var city = await _applicationDbContext.Cities.FindAsync(new object[] { id }, cancellationToken);
        if (city == null)
            return ServiceResult<bool>.NotFound("City");

        if (!operationContext.IsInRole("SuperAdmin"))
        {
            var currentUser = await GetCurrentUserAsync(operationContext, cancellationToken);
            if (currentUser == null)
                return ServiceResult<bool>.Unauthorized("UserNotFound");
            if (city.TenantId != currentUser.TenantId || city.CreatedByUserId != currentUser.Id)
                return ServiceResult<bool>.Forbidden("OnlyDeleteTenantCities");
        }

        _applicationDbContext.Cities.Remove(city);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<object> GetGovernmentsAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default)
    {
        IQueryable<Governament> query = _legacyDbContext.Governaments;
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(item => item.Gov_Name.Contains(term));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync(cancellationToken);
            var items = await query.OrderBy(item => item.Id).Skip((p - 1) * ps).Take(ps).ToListAsync(cancellationToken);
            return new PagedResult<GovernamentDto>
            {
                Items = items.Select(MapGovernment),
                TotalCount = total,
                Page = p,
                PageSize = ps
            };
        }

        var governments = await query.OrderBy(item => item.Id).ToListAsync(cancellationToken);
        return governments.Select(MapGovernment).ToList();
    }

    public async Task<ServiceResult<GovernamentDto>> GetGovernmentAsync(int id, CancellationToken cancellationToken = default)
    {
        var government = await _legacyDbContext.Governaments.FindAsync(new object[] { id }, cancellationToken);
        return government == null ? ServiceResult<GovernamentDto>.NotFound("Government") : ServiceResult<GovernamentDto>.Success(MapGovernment(government));
    }

    public async Task<ServiceResult<GovernamentDto>> CreateGovernmentAsync(CreateGovernamentDto dto, CancellationToken cancellationToken = default)
    {
        var normalizedName = (dto.GovName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(normalizedName))
            return ServiceResult<GovernamentDto>.Validation("GovernmentNameRequired", BuildIssue(nameof(dto.GovName), "required", "GovernmentNameRequired", dto.GovName));

        var exists = await _legacyDbContext.Governaments.AnyAsync(item => item.Gov_Name != null && item.Gov_Name.Trim().ToLower() == normalizedName.ToLower(), cancellationToken);
        if (exists)
            return ServiceResult<GovernamentDto>.Conflict("GovernmentNameExists");

        var maxId = await _legacyDbContext.Governaments.AnyAsync(cancellationToken) ? await _legacyDbContext.Governaments.MaxAsync(item => item.Id, cancellationToken) : 0;
        var government = new Governament { Id = maxId + 1, Gov_Name = normalizedName };
        _legacyDbContext.Governaments.Add(government);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<GovernamentDto>.Success(MapGovernment(government));
    }

    public async Task<ServiceResult<GovernamentDto>> UpdateGovernmentAsync(int id, CreateGovernamentDto dto, CancellationToken cancellationToken = default)
    {
        var government = await _legacyDbContext.Governaments.FindAsync(new object[] { id }, cancellationToken);
        if (government == null)
            return ServiceResult<GovernamentDto>.NotFound("Government");

        var normalizedName = (dto.GovName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(normalizedName))
            return ServiceResult<GovernamentDto>.Validation("GovernmentNameRequired", BuildIssue(nameof(dto.GovName), "required", "GovernmentNameRequired", dto.GovName));

        var exists = await _legacyDbContext.Governaments.AnyAsync(item => item.Id != id && item.Gov_Name != null && item.Gov_Name.Trim().ToLower() == normalizedName.ToLower(), cancellationToken);
        if (exists)
            return ServiceResult<GovernamentDto>.Conflict("GovernmentNameExists");

        government.Gov_Name = normalizedName;
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<GovernamentDto>.Success(MapGovernment(government));
    }

    public async Task<ServiceResult<bool>> DeleteGovernmentAsync(int id, CancellationToken cancellationToken = default)
    {
        var government = await _legacyDbContext.Governaments.FindAsync(new object[] { id }, cancellationToken);
        if (government == null)
            return ServiceResult<bool>.NotFound("Government");

        _legacyDbContext.Governaments.Remove(government);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    private async Task<ApplicationUser?> GetCurrentUserAsync(ServiceOperationContext context, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(context.UserId))
            return null;

        return await _applicationDbContext.Users.SingleOrDefaultAsync(user => user.Id == context.UserId, cancellationToken);
    }

    private static LocationCatalogCityDto MapCity(City city, bool canEdit, bool canDelete) => new()
    {
        Id = city.Id,
        CountryId = city.CountryId,
        NameEn = city.Name,
        NameAr = city.NameAr,
        IsTenantOwned = city.TenantId.HasValue && !string.IsNullOrWhiteSpace(city.CreatedByUserId),
        CanEdit = canEdit,
        CanDelete = canDelete
    };

    private static GovernamentDto MapGovernment(Governament government) => new()
    {
        Id = government.Id,
        GovName = government.Gov_Name
    };

    private static ValidationIssue BuildIssue(string field, string code, string messageKey, object? attemptedValue) => new()
    {
        Field = field,
        Code = code,
        MessageKey = messageKey,
        AttemptedValue = attemptedValue
    };
}
