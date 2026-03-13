using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CustomerPaymentProof
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
    public int? CaseCode { get; set; }
    public double Amount { get; set; }
    public DateOnly PaymentDate { get; set; }
    public string Notes { get; set; } = string.Empty;
    public int? ProofFileId { get; set; }
    public string Status { get; set; } = "Pending";
    public int? BillingPaymentId { get; set; }
    public string ReviewedByUserId { get; set; } = string.Empty;
    public string ReviewedByName { get; set; } = string.Empty;
    public string ReviewNotes { get; set; } = string.Empty;
    public DateTime SubmittedAtUtc { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
    public int FirmId { get; set; }
}
