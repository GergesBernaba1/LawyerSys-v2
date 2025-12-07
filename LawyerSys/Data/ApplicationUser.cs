using Microsoft.AspNetCore.Identity;

public class ApplicationUser : IdentityUser
{
    // Flag used to mark users migrated from legacy Users table who must reset their password
    public bool RequiresPasswordReset { get; set; }
}
