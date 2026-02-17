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
public class ContendersController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public ContendersController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ContenderDto>>> GetContenders([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Contender> query = _context.Contenders;

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c => c.Full_Name.Contains(s) || c.SSN.ToString().Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<ContenderDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = p,
                PageSize = ps
            });
        }

        var contenders = await query.OrderBy(c => c.Id).ToListAsync();
        return Ok(contenders.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ContenderDto>> GetContender(int id)
    {
        var contender = await _context.Contenders.FindAsync(id);
        if (contender == null)
            return NotFound(new { message = "Contender not found" });

        return Ok(MapToDto(contender));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<ContenderDto>> CreateContender([FromBody] CreateContenderDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var contender = new Contender
        {
            Full_Name = dto.FullName,
            SSN = int.TryParse(dto.SSN, out var ssn) ? ssn : 0,
            BirthDate = dto.BirthDate,
            Type = dto.Type
        };

        _context.Contenders.Add(contender);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetContender), new { id = contender.Id }, MapToDto(contender));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateContender(int id, [FromBody] UpdateContenderDto dto)
    {
        var contender = await _context.Contenders.FindAsync(id);
        if (contender == null)
            return NotFound(new { message = "Contender not found" });

        if (dto.FullName != null) contender.Full_Name = dto.FullName;
        if (dto.SSN != null && int.TryParse(dto.SSN, out var ssn)) contender.SSN = ssn;
        if (dto.BirthDate.HasValue) contender.BirthDate = dto.BirthDate.Value;
        if (dto.Type.HasValue) contender.Type = dto.Type;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(contender));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteContender(int id)
    {
        var contender = await _context.Contenders.FindAsync(id);
        if (contender == null)
            return NotFound(new { message = "Contender not found" });

        _context.Contenders.Remove(contender);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Contender deleted" });
    }

    private static ContenderDto MapToDto(Contender c) => new()
    {
        Id = c.Id,
        FullName = c.Full_Name,
        SSN = c.SSN.ToString(),
        BirthDate = c.BirthDate,
        Type = c.Type
    };
}
