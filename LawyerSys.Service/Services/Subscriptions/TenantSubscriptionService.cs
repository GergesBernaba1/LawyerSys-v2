using LawyerSys.Resources;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Services.Subscriptions;

public class TenantSubscriptionService : ITenantSubscriptionService
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public TenantSubscriptionService(
        ApplicationDbContext applicationDbContext,
        IStringLocalizer<SharedResource> localizer)
    {
        _applicationDbContext = applicationDbContext;
        _localizer = localizer;
    }

    public Task<SubscriptionPackage?> GetActivePackageAsync(int packageId, CancellationToken cancellationToken = default)
    {
        return _applicationDbContext.SubscriptionPackages
            .AsNoTracking()
            .SingleOrDefaultAsync(package => package.Id == packageId && package.IsActive, cancellationToken);
    }

    public async Task<TenantSubscription> CreateSubscriptionForTenantAsync(Tenant tenant, int packageId, CancellationToken cancellationToken = default)
    {
        var package = await _applicationDbContext.SubscriptionPackages
            .SingleOrDefaultAsync(item => item.Id == packageId && item.IsActive, cancellationToken);

        if (package == null)
        {
            throw new InvalidOperationException(_localizer["SubscriptionPackageInvalidMessage"].Value);
        }

        var existingSubscription = await _applicationDbContext.TenantSubscriptions
            .AnyAsync(subscription => subscription.TenantId == tenant.Id, cancellationToken);
        if (existingSubscription)
        {
            throw new InvalidOperationException(_localizer["TenantSubscriptionAlreadyExistsMessage"].Value);
        }

        var now = DateTime.UtcNow;
        var currentPeriodEnd = CalculatePeriodEnd(now, package.BillingCycle);
        var nextPeriodEnd = CalculatePeriodEnd(currentPeriodEnd, package.BillingCycle);

        var subscription = new TenantSubscription
        {
            TenantId = tenant.Id,
            SubscriptionPackageId = package.Id,
            Status = tenant.IsActive ? TenantSubscriptionStatus.Active : TenantSubscriptionStatus.PendingActivation,
            StartDateUtc = now,
            EndDateUtc = currentPeriodEnd,
            NextBillingDateUtc = currentPeriodEnd,
            CreatedAtUtc = now,
            UpdatedAtUtc = now,
        };

        _applicationDbContext.TenantSubscriptions.Add(subscription);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);

        _applicationDbContext.TenantBillingTransactions.Add(new TenantBillingTransaction
        {
            TenantId = tenant.Id,
            TenantSubscriptionId = subscription.Id,
            SubscriptionPackageId = package.Id,
            Status = TenantBillingTransactionStatus.Paid,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = now,
            PeriodEndUtc = currentPeriodEnd,
            DueDateUtc = now,
            PaidAtUtc = now,
            Reference = "REGISTRATION",
            Notes = "Initial subscription period",
            CreatedAtUtc = now,
            UpdatedAtUtc = now,
        });

        _applicationDbContext.TenantBillingTransactions.Add(new TenantBillingTransaction
        {
            TenantId = tenant.Id,
            TenantSubscriptionId = subscription.Id,
            SubscriptionPackageId = package.Id,
            Status = TenantBillingTransactionStatus.Pending,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = currentPeriodEnd,
            PeriodEndUtc = nextPeriodEnd,
            DueDateUtc = currentPeriodEnd,
            Notes = "Upcoming renewal",
            CreatedAtUtc = now,
            UpdatedAtUtc = now,
        });

        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return subscription;
    }

    public Task<TenantSubscription?> GetCurrentSubscriptionAsync(int tenantId, CancellationToken cancellationToken = default)
    {
        return _applicationDbContext.TenantSubscriptions
            .Include(subscription => subscription.SubscriptionPackage)
            .Include(subscription => subscription.Tenant)
            .Where(subscription => subscription.TenantId == tenantId)
            .OrderByDescending(subscription => subscription.UpdatedAtUtc)
            .ThenByDescending(subscription => subscription.Id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task EnsureTenantCanLoginAsync(ApplicationUser user, bool isSuperAdmin, CancellationToken cancellationToken = default)
    {
        if (isSuperAdmin)
        {
            return;
        }

        var subscription = await GetCurrentSubscriptionAsync(user.TenantId, cancellationToken);
        if (subscription == null)
        {
            throw new InvalidOperationException(_localizer["TenantSubscriptionMissingMessage"].Value);
        }

        var now = DateTime.UtcNow;
        if (subscription.EndDateUtc <= now)
        {
            if (subscription.Status != TenantSubscriptionStatus.Expired)
            {
                subscription.Status = TenantSubscriptionStatus.Expired;
                subscription.UpdatedAtUtc = now;
                await _applicationDbContext.SaveChangesAsync(cancellationToken);
            }

            throw new InvalidOperationException(_localizer["TenantSubscriptionExpiredMessage"].Value);
        }

        if (subscription.Status == TenantSubscriptionStatus.Suspended)
        {
            throw new InvalidOperationException(_localizer["TenantSubscriptionSuspendedMessage"].Value);
        }

        if (subscription.Status == TenantSubscriptionStatus.PendingActivation)
        {
            var tenant = subscription.Tenant;
            if (tenant != null && tenant.IsActive)
            {
                subscription.Status = TenantSubscriptionStatus.Active;
                subscription.UpdatedAtUtc = now;
                await _applicationDbContext.SaveChangesAsync(cancellationToken);
            }
        }
    }

    public async Task ActivatePendingSubscriptionAsync(int tenantId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetCurrentSubscriptionAsync(tenantId, cancellationToken);
        if (subscription == null)
        {
            return;
        }

        if (subscription.EndDateUtc <= DateTime.UtcNow)
        {
            subscription.Status = TenantSubscriptionStatus.Expired;
        }
        else if (subscription.Status == TenantSubscriptionStatus.PendingActivation)
        {
            subscription.Status = TenantSubscriptionStatus.Active;
        }

        subscription.UpdatedAtUtc = DateTime.UtcNow;
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<TenantSubscription> ChangeTenantPackageAsync(int tenantId, int packageId, CancellationToken cancellationToken = default)
    {
        var package = await _applicationDbContext.SubscriptionPackages
            .SingleOrDefaultAsync(item => item.Id == packageId && item.IsActive, cancellationToken);
        if (package == null)
        {
            throw new InvalidOperationException(_localizer["SubscriptionPackageInvalidMessage"].Value);
        }

        var subscription = await _applicationDbContext.TenantSubscriptions
            .Include(item => item.Tenant)
            .Where(item => item.TenantId == tenantId)
            .OrderByDescending(item => item.UpdatedAtUtc)
            .FirstOrDefaultAsync(cancellationToken);

        if (subscription == null)
        {
            throw new InvalidOperationException(_localizer["TenantSubscriptionMissingMessage"].Value);
        }

        var now = DateTime.UtcNow;
        var currentPeriodEnd = CalculatePeriodEnd(now, package.BillingCycle);
        var nextPeriodEnd = CalculatePeriodEnd(currentPeriodEnd, package.BillingCycle);

        var pendingTransactions = await _applicationDbContext.TenantBillingTransactions
            .Where(item => item.TenantSubscriptionId == subscription.Id && item.Status == TenantBillingTransactionStatus.Pending)
            .ToListAsync(cancellationToken);

        foreach (var pendingTransaction in pendingTransactions)
        {
            pendingTransaction.Status = TenantBillingTransactionStatus.Cancelled;
            pendingTransaction.Notes = "Cancelled because the tenant changed package";
            pendingTransaction.UpdatedAtUtc = now;
        }

        subscription.SubscriptionPackageId = package.Id;
        subscription.StartDateUtc = now;
        subscription.EndDateUtc = currentPeriodEnd;
        subscription.NextBillingDateUtc = currentPeriodEnd;
        subscription.Status = subscription.Tenant.IsActive
            ? TenantSubscriptionStatus.Active
            : TenantSubscriptionStatus.PendingActivation;
        subscription.UpdatedAtUtc = now;

        _applicationDbContext.TenantBillingTransactions.Add(new TenantBillingTransaction
        {
            TenantId = subscription.TenantId,
            TenantSubscriptionId = subscription.Id,
            SubscriptionPackageId = package.Id,
            Status = TenantBillingTransactionStatus.Paid,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = now,
            PeriodEndUtc = currentPeriodEnd,
            DueDateUtc = now,
            PaidAtUtc = now,
            Reference = "PACKAGE-CHANGE",
            Notes = "Current package changed by tenant admin",
            CreatedAtUtc = now,
            UpdatedAtUtc = now,
        });

        _applicationDbContext.TenantBillingTransactions.Add(new TenantBillingTransaction
        {
            TenantId = subscription.TenantId,
            TenantSubscriptionId = subscription.Id,
            SubscriptionPackageId = package.Id,
            Status = TenantBillingTransactionStatus.Pending,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = currentPeriodEnd,
            PeriodEndUtc = nextPeriodEnd,
            DueDateUtc = currentPeriodEnd,
            Notes = "Upcoming renewal",
            CreatedAtUtc = now,
            UpdatedAtUtc = now,
        });

        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return subscription;
    }

    public async Task<TenantBillingTransaction> MarkTransactionPaidAsync(long transactionId, string? reference, string? notes, CancellationToken cancellationToken = default)
    {
        var transaction = await _applicationDbContext.TenantBillingTransactions
            .Include(item => item.TenantSubscription)
                .ThenInclude(subscription => subscription.Tenant)
            .Include(item => item.SubscriptionPackage)
            .SingleOrDefaultAsync(item => item.Id == transactionId, cancellationToken);

        if (transaction == null)
        {
            throw new InvalidOperationException(_localizer["TenantBillingTransactionMissingMessage"].Value);
        }

        if (transaction.Status == TenantBillingTransactionStatus.Paid)
        {
            return transaction;
        }

        var now = DateTime.UtcNow;
        transaction.Status = TenantBillingTransactionStatus.Paid;
        transaction.PaidAtUtc = now;
        transaction.Reference = Normalize(reference);
        transaction.Notes = Normalize(notes);
        transaction.UpdatedAtUtc = now;

        var subscription = transaction.TenantSubscription;
        if (transaction.PeriodEndUtc > subscription.EndDateUtc)
        {
            subscription.StartDateUtc = transaction.PeriodStartUtc;
            subscription.EndDateUtc = transaction.PeriodEndUtc;
            subscription.NextBillingDateUtc = transaction.PeriodEndUtc;
            subscription.Status = subscription.Tenant.IsActive
                ? TenantSubscriptionStatus.Active
                : TenantSubscriptionStatus.PendingActivation;
            subscription.UpdatedAtUtc = now;
        }
        else if (subscription.Status == TenantSubscriptionStatus.Expired && subscription.EndDateUtc > now)
        {
            subscription.Status = TenantSubscriptionStatus.Active;
            subscription.UpdatedAtUtc = now;
        }

        await EnsureUpcomingRenewalTransactionAsync(subscription, transaction.SubscriptionPackage, cancellationToken);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return transaction;
    }

    public async Task<TenantBillingTransaction> MarkTransactionCancelledAsync(long transactionId, string? notes, CancellationToken cancellationToken = default)
    {
        var transaction = await _applicationDbContext.TenantBillingTransactions
            .SingleOrDefaultAsync(item => item.Id == transactionId, cancellationToken);

        if (transaction == null)
        {
            throw new InvalidOperationException(_localizer["TenantBillingTransactionMissingMessage"].Value);
        }

        transaction.Status = TenantBillingTransactionStatus.Cancelled;
        transaction.Notes = Normalize(notes);
        transaction.UpdatedAtUtc = DateTime.UtcNow;
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return transaction;
    }

    private async Task EnsureUpcomingRenewalTransactionAsync(TenantSubscription subscription, SubscriptionPackage package, CancellationToken cancellationToken)
    {
        var exists = await _applicationDbContext.TenantBillingTransactions
            .AnyAsync(item =>
                item.TenantSubscriptionId == subscription.Id &&
                item.Status == TenantBillingTransactionStatus.Pending &&
                item.PeriodStartUtc >= subscription.EndDateUtc,
                cancellationToken);

        if (exists)
        {
            return;
        }

        var nextPeriodEnd = CalculatePeriodEnd(subscription.EndDateUtc, package.BillingCycle);
        _applicationDbContext.TenantBillingTransactions.Add(new TenantBillingTransaction
        {
            TenantId = subscription.TenantId,
            TenantSubscriptionId = subscription.Id,
            SubscriptionPackageId = package.Id,
            Status = TenantBillingTransactionStatus.Pending,
            BillingCycle = package.BillingCycle,
            Amount = package.Price,
            Currency = package.Currency,
            PeriodStartUtc = subscription.EndDateUtc,
            PeriodEndUtc = nextPeriodEnd,
            DueDateUtc = subscription.EndDateUtc,
            Notes = "Upcoming renewal",
            CreatedAtUtc = DateTime.UtcNow,
            UpdatedAtUtc = DateTime.UtcNow,
        });
    }

    private static DateTime CalculatePeriodEnd(DateTime startUtc, SubscriptionBillingCycle billingCycle)
    {
        return billingCycle == SubscriptionBillingCycle.Annual
            ? startUtc.AddYears(1)
            : startUtc.AddMonths(1);
    }

    private static string Normalize(string? value) => (value ?? string.Empty).Trim();
}
