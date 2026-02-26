using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class TimeTrackingEntryDto
{
    public int Id { get; set; }
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string WorkType { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StartedBy { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? EndedAt { get; set; }
    public int DurationMinutes { get; set; }
    public decimal? SuggestedAmount { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class StartTimeTrackingDto
{
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }

    [MaxLength(64)]
    public string? WorkType { get; set; }

    [MaxLength(2000)]
    public string? Description { get; set; }
}

public class StopTimeTrackingDto
{
    [Range(0, 1000000)]
    public decimal? HourlyRate { get; set; }
}

public class TimeTrackingSuggestionDto
{
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public int TotalMinutes { get; set; }
    public decimal SuggestedAmount { get; set; }
}
