using Microsoft.AspNetCore.Identity;

public class ApplicationUser : IdentityUser
{
    // Flag used to mark users migrated from legacy Users table who must reset their password
    public bool RequiresPasswordReset { get; set; }
    
    // Full name of the user for display purposes
    public string FullName { get; set; } = string.Empty;

    public int TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    public int? CountryId { get; set; }
    public Country? Country { get; set; }
}
