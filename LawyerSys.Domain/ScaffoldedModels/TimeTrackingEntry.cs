namespace LawyerSys.Data.ScaffoldedModels;

public partial class TimeTrackingEntry
{
    public int Id { get; set; }
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string WorkType { get; set; } = "General";
    public string? Description { get; set; }
    public string Status { get; set; } = "Running";
    public string StartedBy { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? EndedAt { get; set; }
    public int DurationMinutes { get; set; }
    public decimal? SuggestedAmount { get; set; }
    public DateTime UpdatedAt { get; set; }
}
