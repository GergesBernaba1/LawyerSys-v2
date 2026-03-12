using System;
using System.Collections.Generic;

public class SubscriptionPackage
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string DescriptionAr { get; set; } = string.Empty;
    public string Feature1 { get; set; } = string.Empty;
    public string Feature1Ar { get; set; } = string.Empty;
    public string Feature2 { get; set; } = string.Empty;
    public string Feature2Ar { get; set; } = string.Empty;
    public string Feature3 { get; set; } = string.Empty;
    public string Feature3Ar { get; set; } = string.Empty;
    public SubscriptionOfficeSize OfficeSize { get; set; } = SubscriptionOfficeSize.Small;
    public SubscriptionBillingCycle BillingCycle { get; set; } = SubscriptionBillingCycle.Monthly;
    public decimal Price { get; set; }
    public string Currency { get; set; } = "SAR";
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public ICollection<TenantSubscription> TenantSubscriptions { get; set; } = new List<TenantSubscription>();
    public ICollection<TenantBillingTransaction> BillingTransactions { get; set; } = new List<TenantBillingTransaction>();
}

public enum SubscriptionOfficeSize
{
    Small = 1,
    Medium = 2,
}

public enum SubscriptionBillingCycle
{
    Monthly = 1,
    Annual = 2,
}
