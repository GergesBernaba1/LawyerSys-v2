using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CustomerRequestedDocument
{
    public long Id { get; set; }
    public int CaseCode { get; set; }
    public int CustomerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateOnly? DueDate { get; set; }
    public string Status { get; set; } = "Pending";
    public string RequestedByUserId { get; set; } = string.Empty;
    public string RequestedByName { get; set; } = string.Empty;
    public string CustomerNotes { get; set; } = string.Empty;
    public string ReviewNotes { get; set; } = string.Empty;
    public int? UploadedFileId { get; set; }
    public DateTime RequestedAtUtc { get; set; }
    public DateTime? SubmittedAtUtc { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
    public int FirmId { get; set; }
}
