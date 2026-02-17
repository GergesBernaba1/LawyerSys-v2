using LawyerSys.Data;
using LawyerSys.Services.Email;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LawyerSys.Services.Reminders;

public sealed class TaskReminderOptions
{
    public bool Enabled { get; set; } = true;
    public int PollIntervalMinutes { get; set; } = 1;
    public int LookAheadMinutes { get; set; } = 30;
    public int GraceMinutes { get; set; } = 5;
    public int MaxAttemptsPerRecipient { get; set; } = 3;
}

public sealed class TaskReminderBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<TaskReminderBackgroundService> _logger;
    private readonly IOptions<TaskReminderOptions> _options;
    private readonly ReminderDispatchStore _dispatchStore;

    public TaskReminderBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<TaskReminderBackgroundService> logger,
        IOptions<TaskReminderOptions> options,
        ReminderDispatchStore dispatchStore)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _options = options;
        _dispatchStore = dispatchStore;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (_options.Value.Enabled)
                {
                    await ProcessDueReminders(stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while processing task reminders.");
            }

            var delayMinutes = Math.Max(1, _options.Value.PollIntervalMinutes);
            await Task.Delay(TimeSpan.FromMinutes(delayMinutes), stoppingToken);
        }
    }

    private async Task ProcessDueReminders(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var legacy = scope.ServiceProvider.GetRequiredService<LegacyDbContext>();
        var appDb = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var emailSender = scope.ServiceProvider.GetRequiredService<IEmailSender>();

        var now = DateTime.Now;
        var from = now.AddMinutes(-Math.Max(0, _options.Value.GraceMinutes));
        var to = now.AddMinutes(Math.Max(1, _options.Value.LookAheadMinutes));
        await _dispatchStore.EnsureSchemaAsync(legacy, cancellationToken);

        var dueTasks = await legacy.AdminstrativeTasks
            .Where(t => t.Task_Reminder_Date >= from && t.Task_Reminder_Date <= to)
            .Select(t => new
            {
                t.Id,
                t.Task_Name,
                t.Type,
                t.Task_Date,
                t.Task_Reminder_Date,
                t.Notes,
                t.employee_Id
            })
            .ToListAsync(cancellationToken);

        foreach (var task in dueTasks)
        {
            var reminderKey = $"{task.Id}:{task.Task_Reminder_Date:O}";

            if (!task.employee_Id.HasValue)
                continue;

            var employeeUserName = await legacy.Employees
                .Where(e => e.id == task.employee_Id.Value)
                .Include(e => e.Users)
                .Select(e => e.Users.User_Name)
                .FirstOrDefaultAsync(cancellationToken);

            if (string.IsNullOrWhiteSpace(employeeUserName))
                continue;

            var toEmail = await appDb.Users
                .Where(u => u.UserName == employeeUserName && !string.IsNullOrWhiteSpace(u.Email))
                .Select(u => u.Email)
                .FirstOrDefaultAsync(cancellationToken);

            if (string.IsNullOrWhiteSpace(toEmail))
                continue;

            var subject = $"Task reminder - {task.Task_Name}";
            var body = $@"
<p>This is a reminder for an upcoming administrative task.</p>
<ul>
  <li><strong>Task:</strong> {task.Task_Name}</li>
  <li><strong>Type:</strong> {task.Type}</li>
  <li><strong>Task date:</strong> {task.Task_Date:yyyy-MM-dd}</li>
  <li><strong>Reminder time:</strong> {task.Task_Reminder_Date:yyyy-MM-dd HH:mm}</li>
  <li><strong>Notes:</strong> {task.Notes}</li>
</ul>";

            if (await _dispatchStore.HasSuccessfulDispatchAsync(legacy, "Task", reminderKey, toEmail, cancellationToken))
                continue;

            var attempts = await _dispatchStore.GetAttemptCountAsync(legacy, "Task", reminderKey, toEmail, cancellationToken);
            if (attempts >= Math.Max(1, _options.Value.MaxAttemptsPerRecipient))
                continue;

            try
            {
                await emailSender.SendEmailAsync(toEmail, subject, body);
                await _dispatchStore.RecordAttemptAsync(legacy, "Task", reminderKey, toEmail, subject, "Sent", null, cancellationToken);
                _logger.LogInformation("Task reminder sent for task {TaskId} to {Email}.", task.Id, toEmail);
            }
            catch (Exception ex)
            {
                await _dispatchStore.RecordAttemptAsync(legacy, "Task", reminderKey, toEmail, subject, "Failed", ex.Message, cancellationToken);
                _logger.LogWarning(ex, "Failed to send task reminder for task {TaskId} to {Email}", task.Id, toEmail);
            }
        }
    }
}
