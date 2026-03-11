using System;

public class Notification
{
    public long Id { get; set; }
    public string RecipientUserId { get; set; } = string.Empty;
    public string? SenderUserId { get; set; }
    public int? TenantId { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string TitleAr { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string MessageAr { get; set; } = string.Empty;
    public string? Route { get; set; }
    public string? RelatedEntityType { get; set; }
    public string? RelatedEntityId { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReadAtUtc { get; set; }

    public ApplicationUser? RecipientUser { get; set; }
    public ApplicationUser? SenderUser { get; set; }
    public Tenant? Tenant { get; set; }
}
