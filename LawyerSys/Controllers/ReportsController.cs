using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Services.Reporting;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ReportsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public ReportsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("financial-summary")]
    public async Task<ActionResult<FinancialReportResponseDto>> GetFinancialSummary([FromQuery] int? year = null, [FromQuery] int? month = null, [FromQuery] int? customerId = null)
    {
        var reportMonth = Math.Clamp(month ?? DateTime.UtcNow.Month, 1, 12);
        var reportYear = year ?? DateTime.UtcNow.Year;

        var from = new DateOnly(reportYear, reportMonth, 1);
        var to = from.AddMonths(1).AddDays(-1);

        var paymentsQuery = _context.Billing_Pays.Where(p => p.Date_Of_Opreation >= from && p.Date_Of_Opreation <= to);
        if (customerId.HasValue)
        {
            paymentsQuery = paymentsQuery.Where(p => p.Custmor_Id == customerId.Value);
        }

        var receiptsQuery = _context.Billing_Receipts.Where(r => r.Date_Of_Opreation >= from && r.Date_Of_Opreation <= to);

        var totalPayments = await paymentsQuery.SumAsync(p => p.Amount);
        var totalReceipts = await receiptsQuery.SumAsync(r => r.Amount);

        var monthlyPoints = new List<MonthlyCashFlowPointDto>();
        for (var i = 5; i >= 0; i--)
        {
            var cursor = from.AddMonths(-i);
            var monthFrom = new DateOnly(cursor.Year, cursor.Month, 1);
            var monthTo = monthFrom.AddMonths(1).AddDays(-1);

            var monthlyPaymentsQuery = _context.Billing_Pays.Where(p => p.Date_Of_Opreation >= monthFrom && p.Date_Of_Opreation <= monthTo);
            if (customerId.HasValue)
            {
                monthlyPaymentsQuery = monthlyPaymentsQuery.Where(p => p.Custmor_Id == customerId.Value);
            }

            var monthlyPayments = await monthlyPaymentsQuery.SumAsync(p => p.Amount);
            var monthlyReceipts = await _context.Billing_Receipts
                .Where(r => r.Date_Of_Opreation >= monthFrom && r.Date_Of_Opreation <= monthTo)
                .SumAsync(r => r.Amount);

            monthlyPoints.Add(new MonthlyCashFlowPointDto
            {
                Year = monthFrom.Year,
                Month = monthFrom.Month,
                Payments = monthlyPayments,
                Receipts = monthlyReceipts,
                NetCashFlow = monthlyReceipts - monthlyPayments
            });
        }

        var response = new FinancialReportResponseDto
        {
            Summary = new FinancialSummaryDto
            {
                Year = reportYear,
                Month = reportMonth,
                TotalPayments = totalPayments,
                TotalReceipts = totalReceipts,
                NetCashFlow = totalReceipts - totalPayments,
                PaymentsCount = await paymentsQuery.CountAsync(),
                ReceiptsCount = await receiptsQuery.CountAsync()
            },
            Last6Months = monthlyPoints
        };

        return Ok(response);
    }

    [HttpGet("financial-summary/export")]
    public async Task<IActionResult> ExportFinancialSummary([FromQuery] string format = "csv", [FromQuery] int? year = null, [FromQuery] int? month = null, [FromQuery] int? customerId = null)
    {
        var summaryResult = await GetFinancialSummary(year, month, customerId);
        if (summaryResult.Result is not null)
        {
            return summaryResult.Result;
        }

        var data = summaryResult.Value!;
        var generatedAt = DateTime.UtcNow;

        if (string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase))
        {
            var lines = new List<string>
            {
                $"Generated: {generatedAt:yyyy-MM-dd HH:mm} UTC",
                $"Period: {data.Summary.Year}-{data.Summary.Month:D2}",
                $"Total Payments: {data.Summary.TotalPayments:F2}",
                $"Total Receipts: {data.Summary.TotalReceipts:F2}",
                $"Net Cash Flow: {data.Summary.NetCashFlow:F2}",
                $"Payments Count: {data.Summary.PaymentsCount}",
                $"Receipts Count: {data.Summary.ReceiptsCount}",
                "",
                "Last 6 months:"
            };

            lines.AddRange(data.Last6Months.Select(m => $"{m.Year}-{m.Month:D2}: pay={m.Payments:F2}, receipt={m.Receipts:F2}, net={m.NetCashFlow:F2}"));

            var pdfBytes = ReportExportBuilder.BuildSimplePdf("LawyerSys Financial Summary", lines);
            return File(pdfBytes, "application/pdf", $"financial-summary-{generatedAt:yyyyMMddHHmm}.pdf");
        }

        var csvBytes = ReportExportBuilder.BuildCsv(
            new[] { "Section", "Year", "Month", "Payments", "Receipts", "NetCashFlow", "PaymentsCount", "ReceiptsCount" },
            new[]
            {
                new[]
                {
                    "Summary",
                    data.Summary.Year.ToString(),
                    data.Summary.Month.ToString(),
                    data.Summary.TotalPayments.ToString("F2"),
                    data.Summary.TotalReceipts.ToString("F2"),
                    data.Summary.NetCashFlow.ToString("F2"),
                    data.Summary.PaymentsCount.ToString(),
                    data.Summary.ReceiptsCount.ToString()
                }
            }.Concat(data.Last6Months.Select(m => new[]
            {
                "MonthlyTrend",
                m.Year.ToString(),
                m.Month.ToString(),
                m.Payments.ToString("F2"),
                m.Receipts.ToString("F2"),
                m.NetCashFlow.ToString("F2"),
                string.Empty,
                string.Empty
            }))
        );

        return File(csvBytes, "text/csv", $"financial-summary-{generatedAt:yyyyMMddHHmm}.csv");
    }

    [HttpGet("customers/{customerId}/billing-history")]
    public async Task<ActionResult<CustomerBillingHistoryDto>> GetCustomerBillingHistory(int customerId)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == customerId);

        if (customer is null)
        {
            return NotFound(new { message = "Customer not found" });
        }

        var payments = await _context.Billing_Pays
            .Where(p => p.Custmor_Id == customerId)
            .OrderByDescending(p => p.Date_Of_Opreation)
            .ToListAsync();

        return Ok(new CustomerBillingHistoryDto
        {
            CustomerId = customer.Id,
            CustomerName = customer.Users?.Full_Name ?? $"Customer #{customer.Id}",
            TotalPayments = payments.Sum(p => p.Amount),
            Entries = payments.Select(p => new BillingHistoryEntryDto
            {
                Type = "Payment",
                Id = p.Id,
                Date = p.Date_Of_Opreation,
                Amount = p.Amount,
                Notes = p.Notes
            })
        });
    }

    [HttpGet("outstanding-balances")]
    public async Task<ActionResult<IEnumerable<OutstandingBalanceDto>>> GetOutstandingBalances()
    {
        var customers = await _context.Customers
            .Include(c => c.Users)
            .ToListAsync();

        var caseTotalsByCustomer = await _context.Custmors_Cases
            .Include(cc => cc.Case)
            .GroupBy(cc => cc.Custmors_Id)
            .Select(g => new
            {
                CustomerId = g.Key,
                Total = g.Sum(x => (double)x.Case.Total_Amount)
            })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total);

        var paymentsByCustomer = await _context.Billing_Pays
            .GroupBy(p => p.Custmor_Id)
            .Select(g => new
            {
                CustomerId = g.Key,
                Total = g.Sum(x => x.Amount)
            })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total);

        var result = customers
            .Select(c =>
            {
                var caseTotal = caseTotalsByCustomer.GetValueOrDefault(c.Id, 0);
                var paid = paymentsByCustomer.GetValueOrDefault(c.Id, 0);
                return new OutstandingBalanceDto
                {
                    CustomerId = c.Id,
                    CustomerName = c.Users?.Full_Name ?? $"Customer #{c.Id}",
                    CasesTotalAmount = caseTotal,
                    PaidAmount = paid,
                    OutstandingBalance = caseTotal - paid
                };
            })
            .OrderByDescending(x => x.OutstandingBalance)
            .ToList();

        return Ok(result);
    }
}
