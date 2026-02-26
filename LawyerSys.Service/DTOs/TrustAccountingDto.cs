using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public static class TrustEntryTypes
{
    public const string Deposit = "Deposit";
    public const string Withdrawal = "Withdrawal";
    public const string AdjustmentIncrease = "AdjustmentIncrease";
    public const string AdjustmentDecrease = "AdjustmentDecrease";
}

public class TrustLedgerEntryDto
{
    public int Id { get; set; }
    public int CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public int? CaseCode { get; set; }
    public string EntryType { get; set; } = string.Empty;
    public double Amount { get; set; }
    public DateOnly OperationDate { get; set; }
    public string? Description { get; set; }
    public string? Reference { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public double RunningBalance { get; set; }
}

public class TrustAccountBalanceDto
{
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public double CurrentBalance { get; set; }
    public DateOnly? LastMovementDate { get; set; }
}

public class TrustSummaryDto
{
    public DateOnly AsOfDate { get; set; }
    public double BookBalance { get; set; }
    public double TotalClientLedgerBalance { get; set; }
    public int ActiveClientAccounts { get; set; }
    public int NegativeBalanceAccounts { get; set; }
    public TrustReconciliationDto? LatestReconciliation { get; set; }
}

public class CreateTrustDepositDto
{
    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }

    [Range(0.01, double.MaxValue)]
    public double Amount { get; set; }

    [Required]
    public DateOnly OperationDate { get; set; }

    [Range(1, int.MaxValue)]
    public int? CaseCode { get; set; }

    [MaxLength(1024)]
    public string? Description { get; set; }

    [MaxLength(128)]
    public string? Reference { get; set; }
}

public class CreateTrustWithdrawalDto
{
    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }

    [Range(0.01, double.MaxValue)]
    public double Amount { get; set; }

    [Required]
    public DateOnly OperationDate { get; set; }

    [Range(1, int.MaxValue)]
    public int? CaseCode { get; set; }

    [MaxLength(1024)]
    public string? Description { get; set; }

    [MaxLength(128)]
    public string? Reference { get; set; }
}

public class CreateTrustAdjustmentDto
{
    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }

    [Range(0.01, double.MaxValue)]
    public double Amount { get; set; }

    [Required]
    public DateOnly OperationDate { get; set; }

    [Range(1, int.MaxValue)]
    public int? CaseCode { get; set; }

    [Required]
    [RegularExpression("^(Increase|Decrease)$", ErrorMessage = "Direction must be Increase or Decrease.")]
    public string Direction { get; set; } = "Increase";

    [MaxLength(1024)]
    public string? Description { get; set; }

    [MaxLength(128)]
    public string? Reference { get; set; }
}

public class CreateTrustReconciliationDto
{
    [Range(0, double.MaxValue)]
    public double BankStatementBalance { get; set; }

    [Required]
    public DateOnly ReconciliationDate { get; set; }

    [MaxLength(1024)]
    public string? Notes { get; set; }
}

public class TrustReconciliationDto
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

public class TrustMonthlyTrendPointDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public double Deposits { get; set; }
    public double Withdrawals { get; set; }
    public double NetFlow { get; set; }
    public double EndingBalance { get; set; }
}

public class TrustReconciliationTrendPointDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public int Count { get; set; }
    public double AverageBankToBookDifference { get; set; }
    public double MaxAbsoluteBankToBookDifference { get; set; }
}

public class TrustMonthlyTrendsReportDto
{
    public int Months { get; set; }
    public DateOnly FromMonth { get; set; }
    public DateOnly ToDate { get; set; }
    public int? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public double TotalDeposits { get; set; }
    public double TotalWithdrawals { get; set; }
    public double NetFlow { get; set; }
    public double OpeningBalance { get; set; }
    public double EndingBalance { get; set; }
    public IReadOnlyList<TrustMonthlyTrendPointDto> MonthlyPoints { get; set; } = Array.Empty<TrustMonthlyTrendPointDto>();
    public IReadOnlyList<TrustReconciliationTrendPointDto> ReconciliationPoints { get; set; } = Array.Empty<TrustReconciliationTrendPointDto>();
}
