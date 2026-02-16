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
public class AdminTasksController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public AdminTasksController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetAdminTasks()
    {
        var tasks = await _context.AdminstrativeTasks
            .Include(t => t.employee)
                .ThenInclude(e => e!.Users)
            .ToListAsync();
        return Ok(tasks.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<AdminTaskDto>> GetAdminTask(int id)
    {
        var task = await _context.AdminstrativeTasks
            .Include(t => t.employee)
                .ThenInclude(e => e!.Users)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
            return NotFound(new { message = "Task not found" });

        return Ok(MapToDto(task));
    }

    [HttpGet("upcoming")]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetUpcomingTasks([FromQuery] int days = 7)
    {
        var futureDate = DateTime.Now.AddDays(days);
        var tasks = await _context.AdminstrativeTasks
            .Include(t => t.employee)
                .ThenInclude(e => e!.Users)
            .Where(t => t.Task_Reminder_Date <= futureDate && t.Task_Reminder_Date >= DateTime.Now)
            .OrderBy(t => t.Task_Reminder_Date)
            .ToListAsync();

        return Ok(tasks.Select(MapToDto));
    }

    [HttpGet("byemployee/{employeeId}")]
    public async Task<ActionResult<IEnumerable<AdminTaskDto>>> GetTasksByEmployee(int employeeId)
    {
        var tasks = await _context.AdminstrativeTasks
            .Include(t => t.employee)
                .ThenInclude(e => e!.Users)
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
        }

        return CreatedAtAction(nameof(GetAdminTask), new { id = task.Id }, MapToDto(task));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateAdminTask(int id, [FromBody] UpdateAdminTaskDto dto)
    {
        var task = await _context.AdminstrativeTasks
            .Include(t => t.employee)
                .ThenInclude(e => e!.Users)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null)
            return NotFound(new { message = "Task not found" });

        if (dto.TaskName != null) task.Task_Name = dto.TaskName;
        if (dto.Type != null) task.Type = dto.Type;
        if (dto.TaskDate.HasValue) task.Task_Date = dto.TaskDate.Value;
        if (dto.TaskReminderDate.HasValue) task.Task_Reminder_Date = dto.TaskReminderDate.Value;
        if (dto.Notes != null) task.Notes = dto.Notes;
        if (dto.EmployeeId.HasValue) task.employee_Id = dto.EmployeeId;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(task));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAdminTask(int id)
    {
        var task = await _context.AdminstrativeTasks.FindAsync(id);
        if (task == null)
            return NotFound(new { message = "Task not found" });

        _context.AdminstrativeTasks.Remove(task);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Task deleted" });
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
