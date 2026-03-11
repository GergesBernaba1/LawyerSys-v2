using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
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

    public GovernmentsController(
        LegacyDbContext context,
        ApplicationDbContext applicationDbContext,
        IUserContext userContext)
    {
        _context = context;
        _applicationDbContext = applicationDbContext;
        _userContext = userContext;
    }

    [HttpGet("location-catalog")]
    public async Task<ActionResult<IEnumerable<LocationCatalogCountryDto>>> GetLocationCatalog([FromQuery] int? countryId = null)
    {
        var isAdmin = await _userContext.IsInRoleAsync("Admin");
        var effectiveCountryId = countryId;

        if (!isAdmin)
        {
            var currentUserId = _userContext.GetUserId();
            if (string.IsNullOrWhiteSpace(currentUserId))
            {
                return Ok(Array.Empty<LocationCatalogCountryDto>());
            }

            effectiveCountryId = await _applicationDbContext.Users
                .Where(user => user.Id == currentUserId)
                .Select(user => user.CountryId)
                .FirstOrDefaultAsync();

            if (effectiveCountryId is null or <= 0)
            {
                return Ok(Array.Empty<LocationCatalogCountryDto>());
            }
        }

        IQueryable<Country> query = _applicationDbContext.Countries
            .AsNoTracking()
            .Include(country => country.Cities);

        if (effectiveCountryId.HasValue && effectiveCountryId.Value > 0)
        {
            query = query.Where(country => country.Id == effectiveCountryId.Value);
        }

        var countries = await query
            .OrderBy(country => country.Name)
            .Select(country => new LocationCatalogCountryDto
            {
                Id = country.Id,
                NameEn = country.Name,
                NameAr = country.NameAr,
                CityCount = country.Cities.Count,
                Cities = country.Cities
                    .OrderBy(city => city.Name)
                    .Select(city => new LocationCatalogCityDto
                    {
                        Id = city.Id,
                        CountryId = city.CountryId,
                        NameEn = city.Name,
                        NameAr = city.NameAr
                    })
                    .ToList()
            })
            .ToListAsync();

        return Ok(countries);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("cities/{id}")]
    public async Task<IActionResult> UpdateCity(int id, [FromBody] UpdateLocationCityDto dto)
    {
        var city = await _applicationDbContext.Cities.FindAsync(id);
        if (city == null)
        {
            return NotFound(new { message = "City not found" });
        }

        var nameEn = (dto.NameEn ?? string.Empty).Trim();
        var nameAr = (dto.NameAr ?? string.Empty).Trim();
        if (dto.CountryId <= 0)
        {
            return BadRequest(new { message = "Country is required" });
        }

        if (string.IsNullOrWhiteSpace(nameEn))
        {
            return BadRequest(new { message = "English city name is required" });
        }

        if (string.IsNullOrWhiteSpace(nameAr))
        {
            return BadRequest(new { message = "Arabic city name is required" });
        }

        var countryExists = await _applicationDbContext.Countries.AnyAsync(country => country.Id == dto.CountryId);
        if (!countryExists)
        {
            return BadRequest(new { message = "Country not found" });
        }

        var duplicateExists = await _applicationDbContext.Cities.AnyAsync(existing =>
            existing.Id != id &&
            existing.CountryId == dto.CountryId &&
            existing.Name.ToLower() == nameEn.ToLower());
        if (duplicateExists)
        {
            return BadRequest(new { message = "City name already exists in this country" });
        }

        city.CountryId = dto.CountryId;
        city.Name = nameEn;
        city.NameAr = nameAr;
        await _applicationDbContext.SaveChangesAsync();

        return Ok(new LocationCatalogCityDto
        {
            Id = city.Id,
            CountryId = city.CountryId,
            NameEn = city.Name,
            NameAr = city.NameAr
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("cities/{id}")]
    public async Task<IActionResult> DeleteCity(int id)
    {
        var city = await _applicationDbContext.Cities.FindAsync(id);
        if (city == null)
        {
            return NotFound(new { message = "City not found" });
        }

        _applicationDbContext.Cities.Remove(city);
        await _applicationDbContext.SaveChangesAsync();
        return Ok(new { message = "City deleted" });
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
            return NotFound(new { message = "Government not found" });

        return Ok(new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<GovernamentDto>> CreateGovernment([FromBody] CreateGovernamentDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);
        if (string.IsNullOrWhiteSpace(dto.GovName))
            return BadRequest(new { message = "Government name is required" });

        var normalizedName = dto.GovName.Trim();
        var exists = await _context.Governaments.AnyAsync(g =>
            g.Gov_Name != null && g.Gov_Name.Trim().ToLower() == normalizedName.ToLower());
        if (exists)
            return BadRequest(new { message = "Government name already exists" });

        // Governament.Id uses ValueGeneratedNever, so we must assign it manually
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
            return NotFound(new { message = "Government not found" });
        if (string.IsNullOrWhiteSpace(dto.GovName))
            return BadRequest(new { message = "Government name is required" });

        var normalizedName = dto.GovName.Trim();
        var exists = await _context.Governaments.AnyAsync(g =>
            g.Id != id && g.Gov_Name != null && g.Gov_Name.Trim().ToLower() == normalizedName.ToLower());
        if (exists)
            return BadRequest(new { message = "Government name already exists" });

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
            return NotFound(new { message = "Government not found" });

        _context.Governaments.Remove(gov);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Government deleted" });
    }
}
