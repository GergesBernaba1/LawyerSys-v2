using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services;
using System.Globalization;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CourtsController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IUserContext _userContext;

    public CourtsController(
        LegacyDbContext context,
        ApplicationDbContext applicationDbContext,
        IUserContext userContext)
    {
        _context = context;
        _applicationDbContext = applicationDbContext;
        _userContext = userContext;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CourtDto>>> GetCourts([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Court> query = _context.Courts.Include(c => c.Gov);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c =>
                c.Name.Contains(s) ||
                c.Address.Contains(s) ||
                c.Telephone.Contains(s) ||
                c.Notes.Contains(s) ||
                (c.Gov != null && c.Gov.Gov_Name.Contains(s)));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<CourtDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = p,
                PageSize = ps
            });
        }

        var courts = await query.OrderBy(c => c.Id).ToListAsync();
        return Ok(courts.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CourtDto>> GetCourt(int id)
    {
        var court = await _context.Courts
            .Include(c => c.Gov)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (court == null)
            return NotFound(new { message = "Court not found" });

        return Ok(MapToDto(court));
    }

    [HttpGet("government-options")]
    public async Task<ActionResult<IEnumerable<GovernamentDto>>> GetGovernmentOptions()
    {
        var items = await GetAllowedGovernmentOptionsAsync();
        if (items.Count == 0)
        {
            return Ok(Array.Empty<GovernamentDto>());
        }

        return Ok(items);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<CourtDto>> CreateCourt([FromBody] CreateCourtDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (!await CanUseGovernmentAsync(dto.GovId))
        {
            return BadRequest(new { message = "Selected city is outside the country saved in your profile." });
        }

        var court = new Court
        {
            Name = dto.Name,
            Address = dto.Address,
            Telephone = dto.Telephone,
            Notes = dto.Notes ?? string.Empty,
            Gov_Id = dto.GovId
        };

        _context.Courts.Add(court);
        await _context.SaveChangesAsync();

        await _context.Entry(court).Reference(c => c.Gov).LoadAsync();
        return CreatedAtAction(nameof(GetCourt), new { id = court.Id }, MapToDto(court));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCourt(int id, [FromBody] UpdateCourtDto dto)
    {
        var court = await _context.Courts.Include(c => c.Gov).FirstOrDefaultAsync(c => c.Id == id);
        if (court == null)
            return NotFound(new { message = "Court not found" });

        if (dto.GovId.HasValue && !await CanUseGovernmentAsync(dto.GovId.Value))
        {
            return BadRequest(new { message = "Selected city is outside the country saved in your profile." });
        }

        if (dto.Name != null) court.Name = dto.Name;
        if (dto.Address != null) court.Address = dto.Address;
        if (dto.Telephone != null) court.Telephone = dto.Telephone;
        if (dto.Notes != null) court.Notes = dto.Notes;
        if (dto.GovId.HasValue) court.Gov_Id = dto.GovId.Value;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(court));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCourt(int id)
    {
        var court = await _context.Courts.FindAsync(id);
        if (court == null)
            return NotFound(new { message = "Court not found" });

        _context.Courts.Remove(court);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Court deleted" });
    }

    private static CourtDto MapToDto(Court c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Address = c.Address,
        Telephone = c.Telephone,
        Notes = c.Notes,
        GovId = c.Gov_Id,
        GovernmentName = c.Gov?.Gov_Name
    };

    private async Task<bool> CanUseGovernmentAsync(int governmentId)
    {
        var allowedGovernmentIds = await GetAllowedGovernmentIdsAsync();
        return allowedGovernmentIds.Contains(governmentId);
    }

    private async Task<List<int>> GetAllowedGovernmentIdsAsync()
    {
        var options = await GetAllowedGovernmentOptionsAsync();
        return options.Select(option => option.Id).ToList();
    }

    private async Task<List<GovernamentDto>> GetAllowedGovernmentOptionsAsync()
    {
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return new List<GovernamentDto>();
        }

        var countryId = await _applicationDbContext.Users
            .AsNoTracking()
            .Where(user => user.Id == currentUserId)
            .Select(user => user.CountryId)
            .SingleOrDefaultAsync();

        if (countryId is null or <= 0)
        {
            return new List<GovernamentDto>();
        }

        var cities = await _applicationDbContext.Cities
            .AsNoTracking()
            .Where(city => city.CountryId == countryId.Value)
            .OrderBy(city => city.Name)
            .Select(city => new { city.Name, city.NameAr })
            .ToListAsync();

        if (cities.Count == 0)
        {
            return new List<GovernamentDto>();
        }

        var governments = await _context.Governaments.ToListAsync();
        var byName = governments
            .GroupBy(government => NormalizeGovernmentName(government.Gov_Name))
            .ToDictionary(group => group.Key, group => group.First());

        var nextId = governments.Count == 0 ? 1 : governments.Max(government => government.Id) + 1;
        var items = new List<GovernamentDto>();

        foreach (var city in cities)
        {
            var normalizedEnglish = NormalizeGovernmentName(city.Name);
            var normalizedArabic = NormalizeGovernmentName(city.NameAr);

            if (!byName.TryGetValue(normalizedEnglish, out var government) &&
                !string.IsNullOrWhiteSpace(normalizedArabic) &&
                !byName.TryGetValue(normalizedArabic, out government))
            {
                government = new Governament
                {
                    Id = nextId++,
                    Gov_Name = city.Name
                };

                _context.Governaments.Add(government);
                byName[normalizedEnglish] = government;

                if (!string.IsNullOrWhiteSpace(normalizedArabic))
                {
                    byName[normalizedArabic] = government;
                }
            }

            items.Add(new GovernamentDto
            {
                Id = government.Id,
                GovName = useArabic && !string.IsNullOrWhiteSpace(city.NameAr)
                    ? city.NameAr
                    : city.Name
            });
        }

        if (_context.ChangeTracker.HasChanges())
        {
            await _context.SaveChangesAsync();
        }

        return items;
    }

    private static string NormalizeGovernmentName(string? value)
    {
        return (value ?? string.Empty).Trim().ToLower();
    }
}
