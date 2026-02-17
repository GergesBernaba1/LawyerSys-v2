using LawyerSys.Data;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace LawyerSys.Services.Reminders;

public sealed class ReminderDispatchStore
{
    private readonly SemaphoreSlim _schemaLock = new(1, 1);
    private volatile bool _schemaReady;

    public async Task EnsureSchemaAsync(LegacyDbContext db, CancellationToken cancellationToken = default)
    {
        if (_schemaReady)
            return;

        await _schemaLock.WaitAsync(cancellationToken);
        try
        {
            if (_schemaReady)
                return;

            var sql = @"
IF OBJECT_ID(N'dbo.ReminderDispatches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ReminderDispatches
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ReminderType NVARCHAR(50) NOT NULL,
        ReminderKey NVARCHAR(200) NOT NULL,
        Recipient NVARCHAR(320) NOT NULL,
        Subject NVARCHAR(200) NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        AttemptedAt DATETIME2 NOT NULL CONSTRAINT DF_ReminderDispatches_AttemptedAt DEFAULT SYSUTCDATETIME(),
        SentAt DATETIME2 NULL
    );

    CREATE INDEX IX_ReminderDispatches_Lookup
        ON dbo.ReminderDispatches(ReminderType, ReminderKey, Recipient, Status, AttemptedAt);
END";

            await db.Database.ExecuteSqlRawAsync(sql, cancellationToken);
            _schemaReady = true;
        }
        finally
        {
            _schemaLock.Release();
        }
    }

    public async Task<bool> HasSuccessfulDispatchAsync(
        LegacyDbContext db,
        string reminderType,
        string reminderKey,
        string recipient,
        CancellationToken cancellationToken = default)
    {
        var cmd = db.Database.GetDbConnection().CreateCommand();
        cmd.CommandText = @"SELECT TOP 1 1 FROM dbo.ReminderDispatches 
                            WHERE ReminderType=@type AND ReminderKey=@key AND Recipient=@recipient AND Status='Sent'";
        AddParameter(cmd, "@type", reminderType);
        AddParameter(cmd, "@key", reminderKey);
        AddParameter(cmd, "@recipient", recipient);

        if (cmd.Connection!.State != ConnectionState.Open)
            await cmd.Connection.OpenAsync(cancellationToken);

        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return result != null && result != DBNull.Value;
    }

    public async Task<int> GetAttemptCountAsync(
        LegacyDbContext db,
        string reminderType,
        string reminderKey,
        string recipient,
        CancellationToken cancellationToken = default)
    {
        var cmd = db.Database.GetDbConnection().CreateCommand();
        cmd.CommandText = @"SELECT COUNT(1) FROM dbo.ReminderDispatches 
                            WHERE ReminderType=@type AND ReminderKey=@key AND Recipient=@recipient";
        AddParameter(cmd, "@type", reminderType);
        AddParameter(cmd, "@key", reminderKey);
        AddParameter(cmd, "@recipient", recipient);

        if (cmd.Connection!.State != ConnectionState.Open)
            await cmd.Connection.OpenAsync(cancellationToken);

        var result = await cmd.ExecuteScalarAsync(cancellationToken);
        return Convert.ToInt32(result ?? 0);
    }

    public async Task RecordAttemptAsync(
        LegacyDbContext db,
        string reminderType,
        string reminderKey,
        string recipient,
        string subject,
        string status,
        string? errorMessage,
        CancellationToken cancellationToken = default)
    {
        var cmd = db.Database.GetDbConnection().CreateCommand();
        cmd.CommandText = @"INSERT INTO dbo.ReminderDispatches
                            (ReminderType, ReminderKey, Recipient, Subject, Status, ErrorMessage, AttemptedAt, SentAt)
                            VALUES (@type, @key, @recipient, @subject, @status, @error, SYSUTCDATETIME(),
                                    CASE WHEN @status='Sent' THEN SYSUTCDATETIME() ELSE NULL END)";
        AddParameter(cmd, "@type", reminderType);
        AddParameter(cmd, "@key", reminderKey);
        AddParameter(cmd, "@recipient", recipient);
        AddParameter(cmd, "@subject", subject);
        AddParameter(cmd, "@status", status);
        AddParameter(cmd, "@error", (object?)errorMessage ?? DBNull.Value);

        if (cmd.Connection!.State != ConnectionState.Open)
            await cmd.Connection.OpenAsync(cancellationToken);

        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static void AddParameter(IDbCommand command, string name, object? value)
    {
        var p = command.CreateParameter();
        p.ParameterName = name;
        p.Value = value ?? DBNull.Value;
        command.Parameters.Add(p);
    }
}
