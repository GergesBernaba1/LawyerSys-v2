using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Resources;
using LawyerSys.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Services.Calendar;

public sealed class CalendarService : ICalendarService
{
    private readonly LegacyDbContext _context;
    private readonly IEmployeeAccessService _employeeAccessService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CalendarService(
        LegacyDbContext context,
        IEmployeeAccessService employeeAccessService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _employeeAccessService = employeeAccessService;
        _localizer = localizer;
    }

    public async Task<IReadOnlyList<CalendarEventDto>> GetEventsAsync(DateOnly? fromDate, DateOnly? toDate, CancellationToken cancellationToken = default)
    {
        var from = fromDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(-7));
        var to = toDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(30));
        var isEmployeeOnly = await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync();
        var assignedCaseCodes = isEmployeeOnly ? await _employeeAccessService.GetAssignedCaseCodesAsync() : Array.Empty<int>();
        var employeeId = isEmployeeOnly ? await _employeeAccessService.GetCurrentEmployeeIdAsync() : null;

        var hearingQuery = _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Siting.Siting_Date >= from && cs.Siting.Siting_Date <= to);

        if (isEmployeeOnly)
        {
            hearingQuery = assignedCaseCodes.Length == 0
                ? hearingQuery.Where(_ => false)
                : hearingQuery.Where(cs => assignedCaseCodes.Contains(cs.Case_Code));
        }

        var hearingEvents = await hearingQuery
            .Select(cs => new CalendarEventDto
            {
                Id = $"hearing-{cs.Siting_Id}",
                Type = _localizer["Calendar_Hearing"],
                Title = _localizer["Calendar_HearingTitle", cs.Siting.Judge_Name],
                Start = cs.Siting.Siting_Time,
                End = cs.Siting.Siting_Time.AddHours(1),
                Notes = cs.Siting.Notes,
                CaseCode = cs.Case_Code,
                EntityId = cs.Siting_Id,
                IsReminderEvent = false
            })
            .ToListAsync(cancellationToken);

        var hearingReminderQuery = _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => DateOnly.FromDateTime(cs.Siting.Siting_Notification) >= from && DateOnly.FromDateTime(cs.Siting.Siting_Notification) <= to);

        if (isEmployeeOnly)
        {
            hearingReminderQuery = assignedCaseCodes.Length == 0
                ? hearingReminderQuery.Where(_ => false)
                : hearingReminderQuery.Where(cs => assignedCaseCodes.Contains(cs.Case_Code));
        }

        var hearingReminderEvents = await hearingReminderQuery
            .Select(cs => new CalendarEventDto
            {
                Id = $"hearing-reminder-{cs.Siting_Id}",
                Type = _localizer["Calendar_HearingReminder"],
                Title = _localizer["Calendar_HearingReminderTitle"],
                Start = cs.Siting.Siting_Notification,
                End = cs.Siting.Siting_Notification.AddMinutes(15),
                Notes = cs.Siting.Notes,
                CaseCode = cs.Case_Code,
                EntityId = cs.Siting_Id,
                IsReminderEvent = true
            })
            .ToListAsync(cancellationToken);

        var taskQuery = _context.AdminstrativeTasks
            .Where(t => t.Task_Date >= from && t.Task_Date <= to);

        if (isEmployeeOnly)
        {
            taskQuery = employeeId.HasValue
                ? taskQuery.Where(t => t.employee_Id == employeeId.Value)
                : taskQuery.Where(_ => false);
        }

        var taskEvents = await taskQuery
            .Select(t => new CalendarEventDto
            {
                Id = $"task-{t.Id}",
                Type = _localizer["Calendar_Task"],
                Title = t.Task_Name,
                Start = t.Task_Date.ToDateTime(TimeOnly.MinValue),
                End = t.Task_Date.ToDateTime(TimeOnly.MinValue).AddHours(1),
                Notes = t.Notes,
                EntityId = t.Id,
                IsReminderEvent = false
            })
            .ToListAsync(cancellationToken);

        var taskReminderQuery = _context.AdminstrativeTasks
            .Where(t => DateOnly.FromDateTime(t.Task_Reminder_Date) >= from && DateOnly.FromDateTime(t.Task_Reminder_Date) <= to);

        if (isEmployeeOnly)
        {
            taskReminderQuery = employeeId.HasValue
                ? taskReminderQuery.Where(t => t.employee_Id == employeeId.Value)
                : taskReminderQuery.Where(_ => false);
        }

        var taskReminderEvents = await taskReminderQuery
            .Select(t => new CalendarEventDto
            {
                Id = $"task-reminder-{t.Id}",
                Type = _localizer["Calendar_TaskReminder"],
                Title = _localizer["Calendar_TaskReminderTitle", t.Task_Name],
                Start = t.Task_Reminder_Date,
                End = t.Task_Reminder_Date.AddMinutes(15),
                Notes = t.Notes,
                EntityId = t.Id,
                IsReminderEvent = true
            })
            .ToListAsync(cancellationToken);

        return hearingEvents
            .Concat(hearingReminderEvents)
            .Concat(taskEvents)
            .Concat(taskReminderEvents)
            .OrderBy(e => e.Start)
            .ToList();
    }
}
