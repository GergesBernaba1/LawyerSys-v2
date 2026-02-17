using LawyerSys.Data;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace LawyerSys.Services.MultiTenancy;

public class MultiTenancySchemaInitializer
{
    private readonly LegacyDbContext _context;

    private static readonly string[] TenantScopedTables =
    {
        "AdminstrativeTasks",
        "AuditLogs",
        "Billing_Pay",
        "Billing_Receipt",
        "Cases",
        "CaseStatusHistory",
        "Cases_Contenders",
        "Cases_Courts",
        "Cases_Employees",
        "Cases_Files",
        "Cases_Sitings",
        "Con_Lawyers_Custmors",
        "Consltitions_Custmors",
        "Consulations",
        "Consulations_Employee",
        "Contenders",
        "Contenders_Custmors",
        "Contenders_Lawyers",
        "Courts",
        "Custmors_Cases",
        "Customers",
        "Employees",
        "Files",
        "Governaments",
        "Judicial_Documents",
        "Sitings",
        "Users"
    };

    public MultiTenancySchemaInitializer(LegacyDbContext context)
    {
        _context = context;
    }

    public async Task EnsureCreatedAsync(CancellationToken cancellationToken = default)
    {
        foreach (var table in TenantScopedTables)
        {
            var safeConstraint = $"DF_{table}_FirmId";
            var safeIndex = $"IX_{table}_FirmId";

            var sql = $@"
IF OBJECT_ID(N'dbo.{table}', N'U') IS NOT NULL AND COL_LENGTH('dbo.{table}', 'FirmId') IS NULL
BEGIN
    ALTER TABLE dbo.{table} ADD FirmId INT NOT NULL CONSTRAINT {safeConstraint} DEFAULT(1);
    CREATE INDEX {safeIndex} ON dbo.{table}(FirmId);
END";

            await _context.Database.ExecuteSqlRawAsync(sql, cancellationToken);
        }

        Log.Information("Multi-tenancy FirmId schema ensured for tenant-scoped tables");
    }
}
