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
public class SitingsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public SitingsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SitingDto>>> GetSitings()
    {
        var sitings = await _context.Sitings.ToListAsync();
        return Ok(sitings.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SitingDto>> GetSiting(int id)
    {
        var siting = await _context.Sitings.FindAsync(id);
        if (siting == null)
            return NotFound(new { message = "Siting not found" });

        return Ok(MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<SitingDto>> CreateSiting([FromBody] CreateSitingDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var siting = new Siting
        {
            Siting_Time = dto.SitingTime,
            Siting_Date = dto.SitingDate,
            Siting_Notification = dto.SitingNotification,
            Judge_Name = dto.JudgeName,
            Notes = dto.Notes ?? string.Empty
        };

        _context.Sitings.Add(siting);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSiting), new { id = siting.Id }, MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSiting(int id, [FromBody] UpdateSitingDto dto)
    {
        var siting = await _context.Sitings.FindAsync(id);
        if (siting == null)
            return NotFound(new { message = "Siting not found" });

        if (dto.SitingTime.HasValue) siting.Siting_Time = dto.SitingTime.Value;
        if (dto.SitingDate.HasValue) siting.Siting_Date = dto.SitingDate.Value;
        if (dto.SitingNotification.HasValue) siting.Siting_Notification = dto.SitingNotification.Value;
        if (dto.JudgeName != null) siting.Judge_Name = dto.JudgeName;
        if (dto.Notes != null) siting.Notes = dto.Notes;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSiting(int id)
    {
        var siting = await _context.Sitings.FindAsync(id);
        if (siting == null)
            return NotFound(new { message = "Siting not found" });

        _context.Sitings.Remove(siting);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Siting deleted" });
    }

    private static SitingDto MapToDto(Siting s) => new()
    {
        Id = s.Id,
        SitingTime = s.Siting_Time,
        SitingDate = s.Siting_Date,
        SitingNotification = s.Siting_Notification,
        JudgeName = s.Judge_Name,
        Notes = s.Notes
    };
}
