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
public class CourtsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public CourtsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CourtDto>>> GetCourts()
    {
        var courts = await _context.Courts
            .Include(c => c.Gov)
            .ToListAsync();
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

    [HttpPost]
    public async Task<ActionResult<CourtDto>> CreateCourt([FromBody] CreateCourtDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

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

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCourt(int id, [FromBody] UpdateCourtDto dto)
    {
        var court = await _context.Courts.Include(c => c.Gov).FirstOrDefaultAsync(c => c.Id == id);
        if (court == null)
            return NotFound(new { message = "Court not found" });

        if (dto.Name != null) court.Name = dto.Name;
        if (dto.Address != null) court.Address = dto.Address;
        if (dto.Telephone != null) court.Telephone = dto.Telephone;
        if (dto.Notes != null) court.Notes = dto.Notes;
        if (dto.GovId.HasValue) court.Gov_Id = dto.GovId.Value;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(court));
    }

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
}
