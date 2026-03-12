namespace LawyerSys.Services.Subscriptions;

public interface ITenantSubscriptionService
{
    Task<SubscriptionPackage?> GetActivePackageAsync(int packageId, CancellationToken cancellationToken = default);
    Task<TenantSubscription> CreateSubscriptionForTenantAsync(Tenant tenant, int packageId, CancellationToken cancellationToken = default);
    Task<TenantSubscription?> GetCurrentSubscriptionAsync(int tenantId, CancellationToken cancellationToken = default);
    Task EnsureTenantCanLoginAsync(ApplicationUser user, bool isSuperAdmin, CancellationToken cancellationToken = default);
    Task ActivatePendingSubscriptionAsync(int tenantId, CancellationToken cancellationToken = default);
    Task<TenantSubscription> ChangeTenantPackageAsync(int tenantId, int packageId, CancellationToken cancellationToken = default);
    Task<TenantBillingTransaction> MarkTransactionPaidAsync(long transactionId, string? reference, string? notes, CancellationToken cancellationToken = default);
    Task<TenantBillingTransaction> MarkTransactionCancelledAsync(long transactionId, string? notes, CancellationToken cancellationToken = default);
}
