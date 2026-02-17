using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class GovernmentsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public GovernmentsController(LegacyDbContext context)
    {
        _context = context;
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

        // Governament.Id uses ValueGeneratedNever, so we must assign it manually
        var maxId = await _context.Governaments.AnyAsync()
            ? await _context.Governaments.MaxAsync(g => g.Id)
            : 0;

        var gov = new Governament { Id = maxId + 1, Gov_Name = dto.GovName };
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

        gov.Gov_Name = dto.GovName;
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
