namespace LawyerSys.Data.ScaffoldedModels;

public partial class IntakeLead
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string? NationalId { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? DesiredCaseType { get; set; }
    public string Status { get; set; } = "New";
    public string? QualificationNotes { get; set; }
    public bool ConflictChecked { get; set; }
    public bool HasConflict { get; set; }
    public string? ConflictDetails { get; set; }
    public int? AssignedEmployeeId { get; set; }
    public DateTime? NextFollowUpAt { get; set; }
    public DateTime? AssignedAt { get; set; }
    public int? ConvertedCustomerId { get; set; }
    public int? ConvertedCaseCode { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
