namespace LawyerSys.Data.ScaffoldedModels;

public partial class CourtAutomationFilingSubmission
{
    public long Id { get; set; }

    public string SubmissionId { get; set; } = null!;

    public string PackKey { get; set; } = null!;

    public string FormKey { get; set; } = null!;

    public string FilingChannel { get; set; } = null!;

    public int? CaseCode { get; set; }

    public int? CourtId { get; set; }

    public DateOnly? DueDate { get; set; }

    public string Status { get; set; } = null!;

    public string Message { get; set; } = null!;

    public string ExternalReference { get; set; } = null!;

    public DateTime SubmittedAt { get; set; }

    public DateTime? LastStatusAt { get; set; }

    public DateTime? NextCheckAt { get; set; }

    public string? Notes { get; set; }
}
