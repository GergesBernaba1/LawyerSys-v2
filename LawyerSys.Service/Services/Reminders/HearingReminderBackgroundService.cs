using LawyerSys.Data;
using LawyerSys.Services.Email;
using LawyerSys.Services.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LawyerSys.Services.Reminders;

public sealed class HearingReminderOptions
{
    public bool Enabled { get; set; } = true;
    public int PollIntervalMinutes { get; set; } = 1;
    public int LookAheadMinutes { get; set; } = 30;
    public int GraceMinutes { get; set; } = 5;
    public int MaxAttemptsPerRecipient { get; set; } = 3;
}

public sealed class HearingReminderBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<HearingReminderBackgroundService> _logger;
    private readonly IOptions<HearingReminderOptions> _options;
    private readonly ReminderDispatchStore _dispatchStore;

    public HearingReminderBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<HearingReminderBackgroundService> logger,
        IOptions<HearingReminderOptions> options,
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
                _logger.LogError(ex, "Error while processing hearing reminders.");
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
        var externalMessageSender = scope.ServiceProvider.GetRequiredService<IExternalMessageSender>();

        var now = DateTime.Now;
        var from = now.AddMinutes(-Math.Max(0, _options.Value.GraceMinutes));
        var to = now.AddMinutes(Math.Max(1, _options.Value.LookAheadMinutes));
        await _dispatchStore.EnsureSchemaAsync(legacy, cancellationToken);

        var dueSitings = await legacy.Sitings
            .Where(s => s.Siting_Notification >= from && s.Siting_Notification <= to)
            .Select(s => new
            {
                s.Id,
                s.Siting_Date,
                s.Siting_Time,
                s.Siting_Notification,
                s.Judge_Name
            })
            .ToListAsync(cancellationToken);

        foreach (var siting in dueSitings)
        {
            var reminderKey = $"{siting.Id}:{siting.Siting_Notification:O}";

            var caseCodes = await legacy.Cases_Sitings
                .Where(cs => cs.Siting_Id == siting.Id)
                .Select(cs => cs.Case_Code)
                .Distinct()
                .ToListAsync(cancellationToken);

            if (caseCodes.Count == 0)
                continue;

            var employeeUserNames = await legacy.Cases_Employees
                .Where(ce => caseCodes.Contains(ce.Case_Code))
                .Include(ce => ce.Employee)
                    .ThenInclude(e => e.Users)
                .Select(ce => ce.Employee.Users.User_Name)
                .Where(u => !string.IsNullOrWhiteSpace(u))
                .Distinct()
                .ToListAsync(cancellationToken);

            var customerUserNames = await legacy.Custmors_Cases
                .Where(cc => caseCodes.Contains(cc.Case_Id))
                .Include(cc => cc.Custmors)
                    .ThenInclude(c => c.Users)
                .Select(cc => cc.Custmors.Users.User_Name)
                .Where(u => !string.IsNullOrWhiteSpace(u))
                .Distinct()
                .ToListAsync(cancellationToken);

            var userNames = employeeUserNames
                .Concat(customerUserNames)
                .Distinct()
                .ToList();

            if (userNames.Count == 0)
                continue;

            var emails = await appDb.Users
                .Where(u => u.UserName != null && userNames.Contains(u.UserName) && !string.IsNullOrWhiteSpace(u.Email))
                .Select(u => u.Email!)
                .Distinct()
                .ToListAsync(cancellationToken);

            if (emails.Count == 0)
                continue;

            var subject = $"Hearing reminder - case(s): {string.Join(", ", caseCodes)}";
            var plainMessage = $"Hearing reminder for case(s): {string.Join(", ", caseCodes)}. Judge: {siting.Judge_Name}. Date: {siting.Siting_Date:yyyy-MM-dd}. Time: {siting.Siting_Time:yyyy-MM-dd HH:mm}.";
            var body = $@"
<p>This is a reminder for an upcoming hearing.</p>
<ul>
  <li><strong>Case(s):</strong> {string.Join(", ", caseCodes)}</li>
  <li><strong>Judge:</strong> {siting.Judge_Name}</li>
  <li><strong>Hearing date:</strong> {siting.Siting_Date:yyyy-MM-dd}</li>
  <li><strong>Hearing time:</strong> {siting.Siting_Time:yyyy-MM-dd HH:mm}</li>
  <li><strong>Reminder time:</strong> {siting.Siting_Notification:yyyy-MM-dd HH:mm}</li>
</ul>";

            foreach (var email in emails)
            {
                if (await _dispatchStore.HasSuccessfulDispatchAsync(legacy, "Hearing", reminderKey, email, cancellationToken))
                    continue;

                var attempts = await _dispatchStore.GetAttemptCountAsync(legacy, "Hearing", reminderKey, email, cancellationToken);
                if (attempts >= Math.Max(1, _options.Value.MaxAttemptsPerRecipient))
                    continue;

                try
                {
                    await emailSender.SendEmailAsync(email, subject, body);
                    await _dispatchStore.RecordAttemptAsync(legacy, "Hearing", reminderKey, email, subject, "Sent", null, cancellationToken);
                    _logger.LogInformation("Hearing reminder sent for siting {SitingId} to {Email}.", siting.Id, email);
                }
                catch (Exception ex)
                {
                    await _dispatchStore.RecordAttemptAsync(legacy, "Hearing", reminderKey, email, subject, "Failed", ex.Message, cancellationToken);
                    _logger.LogWarning(ex, "Failed to send hearing reminder for siting {SitingId} to {Email}", siting.Id, email);
                }
            }

            var phones = await legacy.Users
                .Where(u => userNames.Contains(u.User_Name))
                .Select(u => u.Phon_Number.ToString())
                .Where(p => !string.IsNullOrWhiteSpace(p))
                .Distinct()
                .ToListAsync(cancellationToken);

            foreach (var phone in phones)
            {
                var smsRecipient = $"sms:{phone}";
                if (!await _dispatchStore.HasSuccessfulDispatchAsync(legacy, "Hearing", reminderKey, smsRecipient, cancellationToken))
                {
                    var sentSms = await externalMessageSender.SendSmsAsync(phone, plainMessage, cancellationToken);
                    await _dispatchStore.RecordAttemptAsync(
                        legacy,
                        "Hearing",
                        reminderKey,
                        smsRecipient,
                        subject,
                        sentSms ? "Sent" : "Failed",
                        sentSms ? null : "SMS dispatch failed",
                        cancellationToken);
                }

                var whatsappRecipient = $"whatsapp:{phone}";
                if (!await _dispatchStore.HasSuccessfulDispatchAsync(legacy, "Hearing", reminderKey, whatsappRecipient, cancellationToken))
                {
                    var sentWhatsApp = await externalMessageSender.SendWhatsAppAsync(phone, plainMessage, cancellationToken);
                    await _dispatchStore.RecordAttemptAsync(
                        legacy,
                        "Hearing",
                        reminderKey,
                        whatsappRecipient,
                        subject,
                        sentWhatsApp ? "Sent" : "Failed",
                        sentWhatsApp ? null : "WhatsApp dispatch failed",
                        cancellationToken);
                }
            }
        }
    }
}
