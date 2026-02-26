using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class TrustReconciliation
{
    public long Id { get; set; }

    public DateOnly ReconciliationDate { get; set; }

    public double BankStatementBalance { get; set; }

    public double BookBalance { get; set; }

    public double ClientLedgerBalance { get; set; }

    public double BankToBookDifference { get; set; }

    public double ClientToBookDifference { get; set; }

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? CreatedBy { get; set; }
}
