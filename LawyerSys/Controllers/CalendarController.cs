using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CalendarController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public CalendarController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("events")]
    public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEvents([FromQuery] DateOnly? fromDate = null, [FromQuery] DateOnly? toDate = null)
    {
        var from = fromDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(-7));
        var to = toDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(30));

        var hearingEvents = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Siting.Siting_Date >= from && cs.Siting.Siting_Date <= to)
            .Select(cs => new CalendarEventDto
            {
                Id = $"hearing-{cs.Siting_Id}",
                Type = "Hearing",
                Title = $"Hearing - Judge {cs.Siting.Judge_Name}",
                Start = cs.Siting.Siting_Time,
                End = cs.Siting.Siting_Time.AddHours(1),
                Notes = cs.Siting.Notes,
                CaseCode = cs.Case_Code,
                EntityId = cs.Siting_Id,
                IsReminderEvent = false
            })
            .ToListAsync();

        var hearingReminderEvents = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => DateOnly.FromDateTime(cs.Siting.Siting_Notification) >= from && DateOnly.FromDateTime(cs.Siting.Siting_Notification) <= to)
            .Select(cs => new CalendarEventDto
            {
                Id = $"hearing-reminder-{cs.Siting_Id}",
                Type = "HearingReminder",
                Title = "Hearing reminder",
                Start = cs.Siting.Siting_Notification,
                End = cs.Siting.Siting_Notification.AddMinutes(15),
                Notes = cs.Siting.Notes,
                CaseCode = cs.Case_Code,
                EntityId = cs.Siting_Id,
                IsReminderEvent = true
            })
            .ToListAsync();

        var taskEvents = await _context.AdminstrativeTasks
            .Where(t => t.Task_Date >= from && t.Task_Date <= to)
            .Select(t => new CalendarEventDto
            {
                Id = $"task-{t.Id}",
                Type = "Task",
                Title = t.Task_Name,
                Start = t.Task_Date.ToDateTime(TimeOnly.MinValue),
                End = t.Task_Date.ToDateTime(TimeOnly.MinValue).AddHours(1),
                Notes = t.Notes,
                EntityId = t.Id,
                IsReminderEvent = false
            })
            .ToListAsync();

        var taskReminderEvents = await _context.AdminstrativeTasks
            .Where(t => DateOnly.FromDateTime(t.Task_Reminder_Date) >= from && DateOnly.FromDateTime(t.Task_Reminder_Date) <= to)
            .Select(t => new CalendarEventDto
            {
                Id = $"task-reminder-{t.Id}",
                Type = "TaskReminder",
                Title = $"Task reminder - {t.Task_Name}",
                Start = t.Task_Reminder_Date,
                End = t.Task_Reminder_Date.AddMinutes(15),
                Notes = t.Notes,
                EntityId = t.Id,
                IsReminderEvent = true
            })
            .ToListAsync();

        var all = hearingEvents
            .Concat(hearingReminderEvents)
            .Concat(taskEvents)
            .Concat(taskReminderEvents)
            .OrderBy(e => e.Start)
            .ToList();

        return Ok(all);
    }
}
