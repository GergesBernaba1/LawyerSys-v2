using System;
using System.Collections.Generic;

public class TenantSubscription
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public int SubscriptionPackageId { get; set; }
    public TenantSubscriptionStatus Status { get; set; } = TenantSubscriptionStatus.PendingActivation;
    public DateTime StartDateUtc { get; set; } = DateTime.UtcNow;
    public DateTime EndDateUtc { get; set; } = DateTime.UtcNow;
    public DateTime NextBillingDateUtc { get; set; } = DateTime.UtcNow;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public Tenant Tenant { get; set; } = null!;
    public SubscriptionPackage SubscriptionPackage { get; set; } = null!;
    public ICollection<TenantBillingTransaction> BillingTransactions { get; set; } = new List<TenantBillingTransaction>();
}

public enum TenantSubscriptionStatus
{
    PendingActivation = 1,
    Active = 2,
    Expired = 3,
    Suspended = 4,
}
