using LawyerSys.Data;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace LawyerSys.Services.Auditing;

public class AuditLogSchemaInitializer
{
    private readonly LegacyDbContext _context;

    public AuditLogSchemaInitializer(LegacyDbContext context)
    {
        _context = context;
    }

    public async Task EnsureCreatedAsync(CancellationToken cancellationToken = default)
    {
        const string sql = @"
IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs
    (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        EntityName NVARCHAR(128) NOT NULL,
        Action NVARCHAR(16) NOT NULL,
        EntityId NVARCHAR(256) NULL,
        OldValues NVARCHAR(MAX) NULL,
        NewValues NVARCHAR(MAX) NULL,
        UserId NVARCHAR(256) NULL,
        UserName NVARCHAR(256) NULL,
        Timestamp DATETIME2 NOT NULL,
        RequestPath NVARCHAR(512) NULL
    );

    CREATE INDEX IX_AuditLogs_Timestamp ON dbo.AuditLogs(Timestamp DESC);
    CREATE INDEX IX_AuditLogs_EntityName ON dbo.AuditLogs(EntityName);
END";

        await _context.Database.ExecuteSqlRawAsync(sql, cancellationToken);
        Log.Information("AuditLogs table schema ensured");
    }
}
