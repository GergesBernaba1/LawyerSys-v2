using System;
using System.Collections.Generic;

public class Tenant
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public int? CountryId { get; set; }

    public Country? Country { get; set; }
    public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
    public ICollection<TenantSubscription> Subscriptions { get; set; } = new List<TenantSubscription>();
    public ICollection<TenantBillingTransaction> BillingTransactions { get; set; } = new List<TenantBillingTransaction>();

    public bool IsDefaultOffice()
    {
        return string.Equals(Name?.Trim(), "Default Firm", StringComparison.OrdinalIgnoreCase);
    }
}
