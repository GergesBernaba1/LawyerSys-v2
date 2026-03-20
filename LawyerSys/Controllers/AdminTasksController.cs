using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class AdminTasksController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IEmployeeAccessService _employeeAccessService;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public AdminTasksController(
        LegacyDbContext context,
        IEmployeeAccessService employeeAccessService,
        IInAppNotificationService inAppNotificationService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _employeeAccessService = employeeAccessService;
        _inAppNotificationService = inAppNotificationService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetAdminTasks([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<AdminstrativeTask> query = _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users);

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
            if (!employeeId.HasValue)
                return Ok(Array.Empty<AdminTaskDto>());
            query = query.Where(t => t.employee_Id == employeeId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(t => t.Task_Name.Contains(s) || t.Type.Contains(s) || t.Notes.Contains(s)
                || (t.employee != null && t.employee.Users != null && t.employee.Users.Full_Name.Contains(s)));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(t => t.Task_Reminder_Date).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<AdminTaskDto> { Items = items.Select(MapToDto), TotalCount = total, Page = p, PageSize = ps });
        }

        var tasks = await query.OrderBy(t => t.Task_Reminder_Date).ToListAsync();
        return Ok(tasks.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<AdminTaskDto>> GetAdminTask(int id)
    {
        var task = await _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
            return this.EntityNotFound<AdminTaskDto>(_localizer, "Task");
        if (!await CanAccessTaskAsync(task))
            return Forbid();

        return Ok(MapToDto(task));
    }

    [HttpGet("upcoming")]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetUpcomingTasks([FromQuery] int days = 7)
    {
        var futureDate = DateTime.Now.AddDays(days);
        IQueryable<AdminstrativeTask> query = _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users)
            .Where(t => t.Task_Reminder_Date <= futureDate && t.Task_Reminder_Date >= DateTime.Now);

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
            if (!employeeId.HasValue)
                return Ok(Array.Empty<AdminTaskDto>());
            query = query.Where(t => t.employee_Id == employeeId.Value);
        }

        var tasks = await query.OrderBy(t => t.Task_Reminder_Date).ToListAsync();
        return Ok(tasks.Select(MapToDto));
    }

    [HttpGet("byemployee/{employeeId}")]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetTasksByEmployee(int employeeId)
    {
        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var currentEmployeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
            if (!currentEmployeeId.HasValue || currentEmployeeId.Value != employeeId)
                return Forbid();
        }

        var tasks = await _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users)
            .Where(t => t.employee_Id == employeeId)
            .ToListAsync();

        return Ok(tasks.Select(MapToDto));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<AdminTaskDto>> CreateAdminTask([FromBody] CreateAdminTaskDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
            if (!employeeId.HasValue)
                return Forbid();
            dto.EmployeeId = employeeId.Value;
        }

        var task = new AdminstrativeTask
        {
            Task_Name = dto.TaskName,
            Type = dto.Type,
            Task_Date = dto.TaskDate,
            Task_Reminder_Date = dto.TaskReminderDate,
            Notes = dto.Notes ?? string.Empty,
            employee_Id = dto.EmployeeId
        };

        _context.AdminstrativeTasks.Add(task);
        await _context.SaveChangesAsync();

        if (task.employee_Id.HasValue)
        {
            await _context.Entry(task).Reference(t => t.employee).LoadAsync();
            if (task.employee != null)
                await _context.Entry(task.employee).Reference(e => e.Users).LoadAsync();

            await _inAppNotificationService.NotifyEmployeeTaskAssignedAsync(
                task.employee_Id.Value, task.Id, task.Task_Name, task.Task_Reminder_Date, HttpContext.RequestAborted);
        }

        return CreatedAtAction(nameof(GetAdminTask), new { id = task.Id }, MapToDto(task));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateAdminTask(int id, [FromBody] UpdateAdminTaskDto dto)
    {
        var task = await _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
            return this.EntityNotFound(_localizer, "Task");
        if (!await CanAccessTaskAsync(task))
            return Forbid();

        if (dto.TaskName != null) task.Task_Name = dto.TaskName;
        if (dto.Type != null) task.Type = dto.Type;
        if (dto.TaskDate.HasValue) task.Task_Date = dto.TaskDate.Value;
        if (dto.TaskReminderDate.HasValue) task.Task_Reminder_Date = dto.TaskReminderDate.Value;
        if (dto.Notes != null) task.Notes = dto.Notes;
        var previousEmployeeId = task.employee_Id;
        if (dto.EmployeeId.HasValue)
        {
            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
                if (!employeeId.HasValue) return Forbid();
                task.employee_Id = employeeId.Value;
            }
            else
            {
                task.employee_Id = dto.EmployeeId;
            }
        }

        await _context.SaveChangesAsync();

        if (task.employee_Id.HasValue && (previousEmployeeId != task.employee_Id || dto.TaskReminderDate.HasValue || dto.TaskName != null))
        {
            await _inAppNotificationService.NotifyEmployeeTaskAssignedAsync(
                task.employee_Id.Value, task.Id, task.Task_Name, task.Task_Reminder_Date, HttpContext.RequestAborted);
        }

        return Ok(MapToDto(task));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAdminTask(int id)
    {
        var task = await _context.AdminstrativeTasks
            .Include(t => t.employee).ThenInclude(e => e!.Users)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
            return this.EntityNotFound(_localizer, "Task");
        if (!await CanAccessTaskAsync(task))
            return Forbid();

        _context.AdminstrativeTasks.Remove(task);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["TaskDeleted"].Value });
    }

    private async Task<bool> CanAccessTaskAsync(AdminstrativeTask task)
    {
        if (await _employeeAccessService.IsCurrentUserAdminAsync()) return true;
        if (!await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync()) return false;
        var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
        return employeeId.HasValue && task.employee_Id == employeeId.Value;
    }

    private static AdminTaskDto MapToDto(AdminstrativeTask t) => new()
    {
        Id = t.Id,
        TaskName = t.Task_Name,
        Type = t.Type,
        TaskDate = t.Task_Date,
        TaskReminderDate = t.Task_Reminder_Date,
        Notes = t.Notes,
        EmployeeId = t.employee_Id,
        EmployeeName = t.employee?.Users?.Full_Name
    };
}
