using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "AdminOnly")]
[ApiController]
[Route("api/[controller]")]
public class AdministrationController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public AdministrationController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("overview")]
    public async Task<ActionResult<AdministrationOverviewDto>> GetOverview()
    {
        var now = DateTime.Now;
        var result = new AdministrationOverviewDto
        {
            Counts = new AdministrationCountsDto
            {
                Users = await _context.Users.CountAsync(),
                Employees = await _context.Employees.CountAsync(),
                Customers = await _context.Customers.CountAsync(),
                Cases = await _context.Cases.CountAsync(),
                Hearings = await _context.Sitings.CountAsync(),
                Tasks = await _context.AdminstrativeTasks.CountAsync(),
                OverdueTasks = await _context.AdminstrativeTasks.CountAsync(t => t.Task_Reminder_Date < now),
                AuditLogs = await _context.AuditLogs.CountAsync()
            },
            Modules = new List<AdministrationModuleDto>
            {
                new() { Key = "users", Route = "/legacyusers", ApiPath = "/api/LegacyUsers", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "employees", Route = "/employees", ApiPath = "/api/Employees", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "customers", Route = "/customers", ApiPath = "/api/Customers", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "cases", Route = "/cases", ApiPath = "/api/Cases", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "tasks", Route = "/tasks", ApiPath = "/api/AdminTasks", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "trust", Route = "/trust-accounting", ApiPath = "/api/TrustAccounting", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "audit", Route = "/auditlogs", ApiPath = "/api/AuditLogs", CanView = true, CanCreateOrUpdate = false },
                new() { Key = "reports", Route = "/reports", ApiPath = "/api/Reports", CanView = true, CanCreateOrUpdate = false }
            }
        };

        return Ok(result);
    }
}
