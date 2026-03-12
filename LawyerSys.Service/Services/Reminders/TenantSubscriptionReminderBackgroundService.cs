using LawyerSys.Services.Email;
using LawyerSys.Services.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LawyerSys.Services.Reminders;

public sealed class TenantSubscriptionReminderOptions
{
    public bool Enabled { get; set; } = true;
    public int PollIntervalMinutes { get; set; } = 60;
}

public sealed class TenantSubscriptionReminderBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<TenantSubscriptionReminderBackgroundService> _logger;
    private readonly IOptions<TenantSubscriptionReminderOptions> _options;

    public TenantSubscriptionReminderBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<TenantSubscriptionReminderBackgroundService> logger,
        IOptions<TenantSubscriptionReminderOptions> options)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _options = options;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (_options.Value.Enabled)
                {
                    await ProcessDueTransactionsAsync(stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while processing tenant subscription reminders.");
            }

            var delayMinutes = Math.Max(5, _options.Value.PollIntervalMinutes);
            await Task.Delay(TimeSpan.FromMinutes(delayMinutes), stoppingToken);
        }
    }

    private async Task ProcessDueTransactionsAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var appDb = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var emailSender = scope.ServiceProvider.GetRequiredService<IEmailSender>();
        var notificationService = scope.ServiceProvider.GetRequiredService<IInAppNotificationService>();

        var now = DateTime.UtcNow;
        var cutoff = now.AddDays(7);
        var transactions = await appDb.TenantBillingTransactions
            .Include(transaction => transaction.Tenant)
            .Include(transaction => transaction.SubscriptionPackage)
            .Include(transaction => transaction.TenantSubscription)
            .Where(transaction =>
                transaction.Status == TenantBillingTransactionStatus.Pending &&
                transaction.DueDateUtc <= cutoff)
            .OrderBy(transaction => transaction.DueDateUtc)
            .ToListAsync(cancellationToken);

        foreach (var transaction in transactions)
        {
            var daysRemaining = (int)Math.Ceiling((transaction.DueDateUtc - now).TotalDays);

            if (daysRemaining <= 0)
            {
                if (transaction.Status != TenantBillingTransactionStatus.Overdue)
                {
                    transaction.Status = TenantBillingTransactionStatus.Overdue;
                    transaction.UpdatedAtUtc = now;
                }

                if (transaction.TenantSubscription.EndDateUtc <= now &&
                    transaction.TenantSubscription.Status != TenantSubscriptionStatus.Expired)
                {
                    transaction.TenantSubscription.Status = TenantSubscriptionStatus.Expired;
                    transaction.TenantSubscription.UpdatedAtUtc = now;
                }

                if (!transaction.ExpiryNoticeSentAtUtc.HasValue)
                {
                    await notificationService.NotifyTenantSubscriptionExpiredAsync(
                        transaction.Tenant,
                        transaction.SubscriptionPackage,
                        cancellationToken);

                    await SendBillingEmailAsync(
                        appDb,
                        emailSender,
                        transaction.TenantId,
                        "Tenant subscription expired",
                        BuildExpiryEmailBody(transaction),
                        cancellationToken);

                    transaction.ExpiryNoticeSentAtUtc = now;
                    transaction.UpdatedAtUtc = now;
                }

                continue;
            }

            if (daysRemaining <= 1 && !transaction.Reminder1DaySentAtUtc.HasValue)
            {
                await DispatchReminderAsync(appDb, emailSender, notificationService, transaction, 1, cancellationToken);
                transaction.Reminder1DaySentAtUtc = now;
                transaction.UpdatedAtUtc = now;
                continue;
            }

            if (daysRemaining <= 3 && !transaction.Reminder3DaysSentAtUtc.HasValue)
            {
                await DispatchReminderAsync(appDb, emailSender, notificationService, transaction, 3, cancellationToken);
                transaction.Reminder3DaysSentAtUtc = now;
                transaction.UpdatedAtUtc = now;
                continue;
            }

            if (daysRemaining <= 7 && !transaction.Reminder7DaysSentAtUtc.HasValue)
            {
                await DispatchReminderAsync(appDb, emailSender, notificationService, transaction, 7, cancellationToken);
                transaction.Reminder7DaysSentAtUtc = now;
                transaction.UpdatedAtUtc = now;
            }
        }

        await appDb.SaveChangesAsync(cancellationToken);
    }

    private static async Task DispatchReminderAsync(
        ApplicationDbContext appDb,
        IEmailSender emailSender,
        IInAppNotificationService notificationService,
        TenantBillingTransaction transaction,
        int thresholdDays,
        CancellationToken cancellationToken)
    {
        await notificationService.NotifyTenantBillingDueAsync(
            transaction.Tenant,
            transaction.SubscriptionPackage,
            transaction.DueDateUtc,
            thresholdDays,
            cancellationToken);

        var subject = thresholdDays == 1
            ? "Tenant billing due tomorrow"
            : $"Tenant billing due in {thresholdDays} days";

        await SendBillingEmailAsync(
            appDb,
            emailSender,
            transaction.TenantId,
            subject,
            BuildReminderEmailBody(transaction, thresholdDays),
            cancellationToken);
    }

    private static async Task SendBillingEmailAsync(
        ApplicationDbContext appDb,
        IEmailSender emailSender,
        int tenantId,
        string subject,
        string body,
        CancellationToken cancellationToken)
    {
        var tenant = await appDb.Tenants
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == tenantId, cancellationToken);

        var emails = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (!string.IsNullOrWhiteSpace(tenant?.ContactEmail))
        {
            emails.Add(tenant.ContactEmail.Trim());
        }

        var adminEmails = await (
            from user in appDb.Users.AsNoTracking()
            join userRole in appDb.UserRoles.AsNoTracking() on user.Id equals userRole.UserId
            join role in appDb.Roles.AsNoTracking() on userRole.RoleId equals role.Id
            where user.TenantId == tenantId &&
                  !string.IsNullOrWhiteSpace(user.Email) &&
                  (role.NormalizedName == "ADMIN" || role.NormalizedName == "EMPLOYEE")
            select user.Email!
        ).Distinct().ToListAsync(cancellationToken);

        foreach (var email in adminEmails)
        {
            emails.Add(email.Trim());
        }

        foreach (var email in emails)
        {
            await emailSender.SendEmailAsync(email, subject, body);
        }
    }

    private static string BuildReminderEmailBody(TenantBillingTransaction transaction, int daysRemaining)
    {
        return $@"
<div style=""font-family:Arial,sans-serif;color:#111827;line-height:1.8"">
  <h2 style=""margin-bottom:8px;"">Tenant billing reminder</h2>
  <p>Your subscription renewal for <strong>{transaction.Tenant.Name}</strong> is due in <strong>{daysRemaining}</strong> day(s).</p>
  <ul>
    <li><strong>Package:</strong> {transaction.SubscriptionPackage.Name}</li>
    <li><strong>Cycle:</strong> {transaction.BillingCycle}</li>
    <li><strong>Amount:</strong> {transaction.Amount:0.00} {transaction.Currency}</li>
    <li><strong>Due date:</strong> {transaction.DueDateUtc:yyyy-MM-dd}</li>
    <li><strong>Coverage:</strong> {transaction.PeriodStartUtc:yyyy-MM-dd} to {transaction.PeriodEndUtc:yyyy-MM-dd}</li>
  </ul>
  <p>Please review the tenant subscription from the administration billing view.</p>
</div>";
    }

    private static string BuildExpiryEmailBody(TenantBillingTransaction transaction)
    {
        return $@"
<div style=""font-family:Arial,sans-serif;color:#111827;line-height:1.8"">
  <h2 style=""margin-bottom:8px;"">Tenant subscription expired</h2>
  <p>The subscription for <strong>{transaction.Tenant.Name}</strong> has expired and requires billing action.</p>
  <ul>
    <li><strong>Package:</strong> {transaction.SubscriptionPackage.Name}</li>
    <li><strong>Amount:</strong> {transaction.Amount:0.00} {transaction.Currency}</li>
    <li><strong>Expired on:</strong> {transaction.DueDateUtc:yyyy-MM-dd}</li>
  </ul>
</div>";
    }
}
