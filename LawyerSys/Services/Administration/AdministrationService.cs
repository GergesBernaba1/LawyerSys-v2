using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Administration;

public sealed class AdministrationService : IAdministrationService
{
    private readonly LegacyDbContext _context;

    public AdministrationService(LegacyDbContext context)
    {
        _context = context;
    }

    public async Task<AdministrationOverviewDto> GetOverviewAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.Now;
        return new AdministrationOverviewDto
        {
            Counts = new AdministrationCountsDto
            {
                Users = await _context.Users.CountAsync(cancellationToken),
                Employees = await _context.Employees.CountAsync(cancellationToken),
                Customers = await _context.Customers.CountAsync(cancellationToken),
                Cases = await _context.Cases.CountAsync(cancellationToken),
                Hearings = await _context.Sitings.CountAsync(cancellationToken),
                Tasks = await _context.AdminstrativeTasks.CountAsync(cancellationToken),
                OverdueTasks = await _context.AdminstrativeTasks.CountAsync(t => t.Task_Reminder_Date < now, cancellationToken),
                AuditLogs = await _context.AuditLogs.CountAsync(cancellationToken)
            },
            Modules = new List<AdministrationModuleDto>
            {
                new() { Key = "users", Route = "/users", ApiPath = "/api/Users", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "employees", Route = "/employees", ApiPath = "/api/Employees", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "customers", Route = "/customers", ApiPath = "/api/Customers", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "cases", Route = "/cases", ApiPath = "/api/Cases", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "tasks", Route = "/tasks", ApiPath = "/api/AdminTasks", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "trust", Route = "/trust-accounting", ApiPath = "/api/TrustAccounting", CanView = true, CanCreateOrUpdate = true },
                new() { Key = "audit", Route = "/auditlogs", ApiPath = "/api/AuditLogs", CanView = true, CanCreateOrUpdate = false },
                new() { Key = "reports", Route = "/reports", ApiPath = "/api/Reports", CanView = true, CanCreateOrUpdate = false }
            }
        };
    }
}
