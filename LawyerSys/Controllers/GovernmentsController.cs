using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using System.Globalization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class GovernmentsController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IUserContext _userContext;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public GovernmentsController(
        LegacyDbContext context,
        ApplicationDbContext applicationDbContext,
        IUserContext userContext,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _applicationDbContext = applicationDbContext;
        _userContext = userContext;
        _localizer = localizer;
    }

    [HttpGet("location-catalog")]
    public async Task<ActionResult<IEnumerable<LocationCatalogCountryDto>>> GetLocationCatalog([FromQuery] int? countryId = null)
    {
        var isSuperAdmin = await _userContext.IsInRoleAsync("SuperAdmin");
        var currentUserId = _userContext.GetUserId();
        var effectiveCountryId = countryId;
        var currentTenantId = _userContext.GetTenantId();
        ApplicationUser? currentUser = null;

        if (!isSuperAdmin)
        {
            if (string.IsNullOrWhiteSpace(currentUserId))
                return Ok(Array.Empty<LocationCatalogCountryDto>());

            currentUser = await _applicationDbContext.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == currentUserId);
            effectiveCountryId = currentUser?.CountryId;
            currentTenantId ??= currentUser?.TenantId;

            if (effectiveCountryId is null or <= 0)
                return Ok(Array.Empty<LocationCatalogCountryDto>());
        }

        IQueryable<Country> query = _applicationDbContext.Countries.AsNoTracking().Include(c => c.Cities);

        if (effectiveCountryId.HasValue && effectiveCountryId.Value > 0)
            query = query.Where(c => c.Id == effectiveCountryId.Value);

        var countries = await query
            .OrderBy(c => c.Name)
            .Select(c => new LocationCatalogCountryDto
            {
                Id = c.Id,
                NameEn = c.Name,
                NameAr = c.NameAr,
                CityCount = c.Cities.Count,
                Cities = c.Cities
                    .OrderBy(city => city.Name)
                    .Select(city => new LocationCatalogCityDto
                    {
                        Id = city.Id,
                        CountryId = city.CountryId,
                        NameEn = city.Name,
                        NameAr = city.NameAr,
                        IsTenantOwned = city.TenantId.HasValue && city.CreatedByUserId != null,
                        CanEdit = isSuperAdmin || (currentTenantId.HasValue && !string.IsNullOrWhiteSpace(currentUserId) && city.TenantId == currentTenantId.Value && city.CreatedByUserId == currentUserId),
                        CanDelete = isSuperAdmin || (currentTenantId.HasValue && !string.IsNullOrWhiteSpace(currentUserId) && city.TenantId == currentTenantId.Value && city.CreatedByUserId == currentUserId)
                    })
                    .ToList()
            })
            .ToListAsync();

        return Ok(countries);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("cities")]
    public async Task<ActionResult<LocationCatalogCityDto>> CreateCity([FromBody] UpdateLocationCityDto dto)
    {
        var nameEn = (dto.NameEn ?? string.Empty).Trim();
        var nameAr = (dto.NameAr ?? string.Empty).Trim();

        if (dto.CountryId <= 0)
            return BadRequest(new { message = _localizer["CountryRequired"].Value });
        if (string.IsNullOrWhiteSpace(nameEn))
            return BadRequest(new { message = _localizer["EnglishCityNameRequired"].Value });
        if (string.IsNullOrWhiteSpace(nameAr))
            return BadRequest(new { message = _localizer["ArabicCityNameRequired"].Value });

        var isSuperAdmin = await _userContext.IsInRoleAsync("SuperAdmin");
        var currentUser = await GetCurrentUserAsync();
        if (!isSuperAdmin)
        {
            if (currentUser == null)
                return Unauthorized(new { message = _localizer["UserNotFound"].Value });
            if (currentUser.CountryId is null or <= 0 || currentUser.CountryId.Value != dto.CountryId)
                return ForbiddenMessage(_localizer["OnlyAddCitiesToProfileCountry"].Value);
            if (currentUser.TenantId <= 0)
                return BadRequest(new { message = _localizer["TenantNotFoundForUser"].Value });
        }

        if (!await _applicationDbContext.Countries.AnyAsync(c => c.Id == dto.CountryId))
            return BadRequest(new { message = _localizer["CountryNotFound"].Value });

        var duplicateExists = await _applicationDbContext.Cities.AnyAsync(e =>
            e.CountryId == dto.CountryId && e.Name.ToLower() == nameEn.ToLower());
        if (duplicateExists)
            return BadRequest(new { message = _localizer["CityNameExists"].Value });

        var city = new City
        {
            CountryId = dto.CountryId,
            Name = nameEn,
            NameAr = nameAr,
            TenantId = isSuperAdmin ? null : currentUser?.TenantId,
            CreatedByUserId = isSuperAdmin ? null : currentUser?.Id
        };

        _applicationDbContext.Cities.Add(city);
        await _applicationDbContext.SaveChangesAsync();

        return Ok(new LocationCatalogCityDto
        {
            Id = city.Id,
            CountryId = city.CountryId,
            NameEn = city.Name,
            NameAr = city.NameAr,
            IsTenantOwned = city.TenantId.HasValue && !string.IsNullOrWhiteSpace(city.CreatedByUserId),
            CanEdit = true,
            CanDelete = true
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("cities/{id}")]
    public async Task<IActionResult> UpdateCity(int id, [FromBody] UpdateLocationCityDto dto)
    {
        var city = await _applicationDbContext.Cities.FindAsync(id);
        if (city == null)
            return this.EntityNotFound(_localizer, "City");

        var nameEn = (dto.NameEn ?? string.Empty).Trim();
        var nameAr = (dto.NameAr ?? string.Empty).Trim();

        if (dto.CountryId <= 0)
            return BadRequest(new { message = _localizer["CountryRequired"].Value });
        if (string.IsNullOrWhiteSpace(nameEn))
            return BadRequest(new { message = _localizer["EnglishCityNameRequired"].Value });
        if (string.IsNullOrWhiteSpace(nameAr))
            return BadRequest(new { message = _localizer["ArabicCityNameRequired"].Value });

        var isSuperAdmin = await _userContext.IsInRoleAsync("SuperAdmin");
        var currentUser = await GetCurrentUserAsync();
        if (!isSuperAdmin)
        {
            if (currentUser == null)
                return Unauthorized(new { message = _localizer["UserNotFound"].Value });
            if (city.TenantId != currentUser.TenantId || city.CreatedByUserId != currentUser.Id)
                return ForbiddenMessage(_localizer["OnlyUpdateTenantCities"].Value);
            if (currentUser.CountryId is null or <= 0 || currentUser.CountryId.Value != dto.CountryId)
                return ForbiddenMessage(_localizer["OnlyMoveCitiesInsideProfileCountry"].Value);
        }

        if (!await _applicationDbContext.Countries.AnyAsync(c => c.Id == dto.CountryId))
            return BadRequest(new { message = _localizer["CountryNotFound"].Value });

        var duplicateExists = await _applicationDbContext.Cities.AnyAsync(e =>
            e.Id != id && e.CountryId == dto.CountryId && e.Name.ToLower() == nameEn.ToLower());
        if (duplicateExists)
            return BadRequest(new { message = _localizer["CityNameExists"].Value });

        city.CountryId = dto.CountryId;
        city.Name = nameEn;
        city.NameAr = nameAr;
        await _applicationDbContext.SaveChangesAsync();

        return Ok(new LocationCatalogCityDto
        {
            Id = city.Id,
            CountryId = city.CountryId,
            NameEn = city.Name,
            NameAr = city.NameAr,
            IsTenantOwned = city.TenantId.HasValue && !string.IsNullOrWhiteSpace(city.CreatedByUserId),
            CanEdit = true,
            CanDelete = isSuperAdmin || (currentUser != null && city.TenantId == currentUser.TenantId && city.CreatedByUserId == currentUser.Id)
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("cities/{id}")]
    public async Task<IActionResult> DeleteCity(int id)
    {
        var city = await _applicationDbContext.Cities.FindAsync(id);
        if (city == null)
            return this.EntityNotFound(_localizer, "City");

        var isSuperAdmin = await _userContext.IsInRoleAsync("SuperAdmin");
        if (!isSuperAdmin)
        {
            var currentUser = await GetCurrentUserAsync();
            if (currentUser == null)
                return Unauthorized(new { message = _localizer["UserNotFound"].Value });
            if (city.TenantId != currentUser.TenantId || city.CreatedByUserId != currentUser.Id)
                return ForbiddenMessage(_localizer["OnlyDeleteTenantCities"].Value);
        }

        _applicationDbContext.Cities.Remove(city);
        await _applicationDbContext.SaveChangesAsync();
        return Ok(new { message = _localizer["CityDeleted"].Value });
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<GovernamentDto>>> GetGovernments([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Governament> query = _context.Governaments;

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(g => g.Gov_Name.Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(g => g.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<GovernamentDto>
            {
                Items = items.Select(g => new GovernamentDto { Id = g.Id, GovName = g.Gov_Name }),
                TotalCount = total,
                Page = p,
                PageSize = ps
            });
        }

        var govs = await query.OrderBy(g => g.Id).ToListAsync();
        return Ok(govs.Select(g => new GovernamentDto { Id = g.Id, GovName = g.Gov_Name }));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<GovernamentDto>> GetGovernment(int id)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return this.EntityNotFound<GovernamentDto>(_localizer, "Government");
        return Ok(new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<GovernamentDto>> CreateGovernment([FromBody] CreateGovernamentDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);
        if (string.IsNullOrWhiteSpace(dto.GovName))
            return BadRequest(new { message = _localizer["GovernmentNameRequired"].Value });

        var normalizedName = dto.GovName.Trim();
        var exists = await _context.Governaments.AnyAsync(g =>
            g.Gov_Name != null && g.Gov_Name.Trim().ToLower() == normalizedName.ToLower());
        if (exists)
            return BadRequest(new { message = _localizer["GovernmentNameExists"].Value });

        var maxId = await _context.Governaments.AnyAsync()
            ? await _context.Governaments.MaxAsync(g => g.Id)
            : 0;

        var gov = new Governament { Id = maxId + 1, Gov_Name = normalizedName };
        _context.Governaments.Add(gov);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetGovernment), new { id = gov.Id }, new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateGovernment(int id, [FromBody] CreateGovernamentDto dto)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return this.EntityNotFound(_localizer, "Government");
        if (string.IsNullOrWhiteSpace(dto.GovName))
            return BadRequest(new { message = _localizer["GovernmentNameRequired"].Value });

        var normalizedName = dto.GovName.Trim();
        var exists = await _context.Governaments.AnyAsync(g =>
            g.Id != id && g.Gov_Name != null && g.Gov_Name.Trim().ToLower() == normalizedName.ToLower());
        if (exists)
            return BadRequest(new { message = _localizer["GovernmentNameExists"].Value });

        gov.Gov_Name = normalizedName;
        await _context.SaveChangesAsync();
        return Ok(new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteGovernment(int id)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return this.EntityNotFound(_localizer, "Government");

        _context.Governaments.Remove(gov);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["GovernmentDeleted"].Value });
    }

    private async Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)) return null;
        return await _applicationDbContext.Users.SingleOrDefaultAsync(u => u.Id == currentUserId);
    }

    private ObjectResult ForbiddenMessage(string message)
        => StatusCode(StatusCodes.Status403Forbidden, new { message });
}
