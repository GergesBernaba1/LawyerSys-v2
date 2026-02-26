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
        "ESignatureRequests",
        "Employees",
        "Files",
        "Governaments",
        "IntakeLeads",
        "Judicial_Documents",
        "Sitings",
        "TimeTrackingEntries",
        "TrustLedgerEntries",
        "TrustReconciliations",
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
            var safeIndex = $"IX_{table}_FirmId";

            var sql = $"""
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND lower(table_name) = lower('{table}')
    ) THEN
        EXECUTE 'ALTER TABLE "{table}" ADD COLUMN IF NOT EXISTS "FirmId" INTEGER NOT NULL DEFAULT 1';
        EXECUTE 'CREATE INDEX IF NOT EXISTS "{safeIndex}" ON "{table}" ("FirmId")';
    END IF;
END $$;
""";

            await _context.Database.ExecuteSqlRawAsync(sql, cancellationToken);
        }

        Log.Information("Multi-tenancy FirmId schema ensured for tenant-scoped tables");
    }
}
