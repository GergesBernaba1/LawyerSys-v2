namespace LawyerSys.DTOs;

public class FinancialSummaryDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public double TotalPayments { get; set; }
    public double TotalReceipts { get; set; }
    public double NetCashFlow { get; set; }
    public int PaymentsCount { get; set; }
    public int ReceiptsCount { get; set; }
}

public class MonthlyCashFlowPointDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public double Payments { get; set; }
    public double Receipts { get; set; }
    public double NetCashFlow { get; set; }
}

public class FinancialReportResponseDto
{
    public FinancialSummaryDto Summary { get; set; } = new();
    public IEnumerable<MonthlyCashFlowPointDto> Last6Months { get; set; } = Array.Empty<MonthlyCashFlowPointDto>();
}

public class BillingHistoryEntryDto
{
    public string Type { get; set; } = string.Empty;
    public int Id { get; set; }
    public DateOnly Date { get; set; }
    public double Amount { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public class CustomerBillingHistoryDto
{
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public double TotalPayments { get; set; }
    public IEnumerable<BillingHistoryEntryDto> Entries { get; set; } = Array.Empty<BillingHistoryEntryDto>();
}

public class OutstandingBalanceDto
{
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public double CasesTotalAmount { get; set; }
    public double PaidAmount { get; set; }
    public double OutstandingBalance { get; set; }
}

public class CalendarEventDto
{
    public string Id { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public DateTime Start { get; set; }
    public DateTime? End { get; set; }
    public string? Notes { get; set; }
    public int? CaseCode { get; set; }
    public int? EntityId { get; set; }
    public bool IsReminderEvent { get; set; }
}

public class CaseTimelineDto
{
    public int CaseCode { get; set; }
    public string CaseType { get; set; } = string.Empty;
    public IEnumerable<CaseTimelineEventDto> Events { get; set; } = Array.Empty<CaseTimelineEventDto>();
}

public class CaseTimelineEventDto
{
    public string Category { get; set; } = string.Empty;
    public DateTime OccurredAt { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int? EntityId { get; set; }
}
