using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class TrustLedgerEntry
{
    public int Id { get; set; }

    public int CustomerId { get; set; }

    public int? CaseCode { get; set; }

    public string EntryType { get; set; } = null!;

    public double Amount { get; set; }

    public DateOnly OperationDate { get; set; }

    public string? Description { get; set; }

    public string? Reference { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? CreatedBy { get; set; }

    public virtual Customer Customer { get; set; } = null!;

    public virtual Case? Case { get; set; }
}
