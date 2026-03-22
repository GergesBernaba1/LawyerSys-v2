using System;

public class UserPushToken
{
    public long Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? LastSeenAtUtc { get; set; }

    public ApplicationUser? User { get; set; }
}
