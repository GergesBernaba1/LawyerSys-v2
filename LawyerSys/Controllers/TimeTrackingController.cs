using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class TimeTrackingController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public TimeTrackingController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TimeTrackingEntryDto>>> GetEntries([FromQuery] string? status = null)
    {
        IQueryable<TimeTrackingEntry> query = _context.TimeTrackingEntries.OrderByDescending(x => x.StartedAt);

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalized = status.Trim();
            query = query.Where(x => x.Status == normalized);
        }

        var items = await query.ToListAsync();
        return Ok(items.Select(MapToDto));
    }

    [HttpPost("start")]
    public async Task<ActionResult<TimeTrackingEntryDto>> Start([FromBody] StartTimeTrackingDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var now = DateTime.UtcNow;
        var item = new TimeTrackingEntry
        {
            CaseCode = dto.CaseCode,
            CustomerId = dto.CustomerId,
            WorkType = string.IsNullOrWhiteSpace(dto.WorkType) ? "General" : dto.WorkType.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            Status = "Running",
            StartedBy = User.Identity?.Name ?? "System",
            StartedAt = now,
            UpdatedAt = now
        };

        _context.TimeTrackingEntries.Add(item);
        await _context.SaveChangesAsync();

        return Ok(MapToDto(item));
    }

    [HttpPost("{id}/stop")]
    public async Task<ActionResult<TimeTrackingEntryDto>> Stop(int id, [FromBody] StopTimeTrackingDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var item = await _context.TimeTrackingEntries.FirstOrDefaultAsync(x => x.Id == id);
        if (item == null) return NotFound(new { message = "Time entry not found" });
        if (!item.Status.Equals("Running", StringComparison.OrdinalIgnoreCase))
            return BadRequest(new { message = "Time entry already stopped" });

        var now = DateTime.UtcNow;
        item.EndedAt = now;
        item.DurationMinutes = Math.Max(0, (int)Math.Round((now - item.StartedAt).TotalMinutes));
        item.Status = "Stopped";
        item.UpdatedAt = now;

        if (dto.HourlyRate.HasValue)
        {
            item.SuggestedAmount = Math.Round((decimal)item.DurationMinutes / 60m * dto.HourlyRate.Value, 2);
        }

        await _context.SaveChangesAsync();

        return Ok(MapToDto(item));
    }

    [HttpGet("suggestions")]
    public async Task<ActionResult<IEnumerable<TimeTrackingSuggestionDto>>> GetSuggestions([FromQuery] decimal hourlyRate = 0)
    {
        if (hourlyRate < 0) return BadRequest(new { message = "hourlyRate must be non-negative" });

        var grouped = await _context.TimeTrackingEntries
            .Where(x => x.Status == "Stopped")
            .GroupBy(x => new { x.CaseCode, x.CustomerId })
            .Select(g => new TimeTrackingSuggestionDto
            {
                CaseCode = g.Key.CaseCode,
                CustomerId = g.Key.CustomerId,
                TotalMinutes = g.Sum(x => x.DurationMinutes),
                SuggestedAmount = hourlyRate > 0
                    ? Math.Round((decimal)g.Sum(x => x.DurationMinutes) / 60m * hourlyRate, 2)
                    : Math.Round(g.Where(x => x.SuggestedAmount.HasValue).Sum(x => x.SuggestedAmount ?? 0m), 2)
            })
            .OrderByDescending(x => x.TotalMinutes)
            .ToListAsync();

        return Ok(grouped);
    }

    private static TimeTrackingEntryDto MapToDto(TimeTrackingEntry x) => new()
    {
        Id = x.Id,
        CaseCode = x.CaseCode,
        CustomerId = x.CustomerId,
        WorkType = x.WorkType,
        Description = x.Description,
        Status = x.Status,
        StartedBy = x.StartedBy,
        StartedAt = x.StartedAt,
        EndedAt = x.EndedAt,
        DurationMinutes = x.DurationMinutes,
        SuggestedAmount = x.SuggestedAmount,
        UpdatedAt = x.UpdatedAt
    };
}
