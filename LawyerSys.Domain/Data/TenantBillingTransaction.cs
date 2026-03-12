using System;

public class TenantBillingTransaction
{
    public long Id { get; set; }
    public int TenantId { get; set; }
    public int TenantSubscriptionId { get; set; }
    public int SubscriptionPackageId { get; set; }
    public TenantBillingTransactionStatus Status { get; set; } = TenantBillingTransactionStatus.Pending;
    public SubscriptionBillingCycle BillingCycle { get; set; } = SubscriptionBillingCycle.Monthly;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "SAR";
    public DateTime PeriodStartUtc { get; set; } = DateTime.UtcNow;
    public DateTime PeriodEndUtc { get; set; } = DateTime.UtcNow;
    public DateTime DueDateUtc { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAtUtc { get; set; }
    public string Reference { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? Reminder7DaysSentAtUtc { get; set; }
    public DateTime? Reminder3DaysSentAtUtc { get; set; }
    public DateTime? Reminder1DaySentAtUtc { get; set; }
    public DateTime? ExpiryNoticeSentAtUtc { get; set; }

    public Tenant Tenant { get; set; } = null!;
    public TenantSubscription TenantSubscription { get; set; } = null!;
    public SubscriptionPackage SubscriptionPackage { get; set; } = null!;
}

public enum TenantBillingTransactionStatus
{
    Pending = 1,
    Paid = 2,
    Cancelled = 3,
    Overdue = 4,
}
