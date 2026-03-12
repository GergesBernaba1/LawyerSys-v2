using System;

public class DemoRequest
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string OfficeName { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public DemoRequestStatus Status { get; set; } = DemoRequestStatus.Pending;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReviewedAtUtc { get; set; }
    public string? ReviewedByUserId { get; set; }

    public ApplicationUser? ReviewedByUser { get; set; }
}

public enum DemoRequestStatus
{
    Pending = 1,
    Approved = 2,
    Rejected = 3,
}
