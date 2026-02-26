using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services.Reporting;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TrustAccountingController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public TrustAccountingController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("accounts")]
    public async Task<ActionResult<IEnumerable<TrustAccountBalanceDto>>> GetAccounts([FromQuery] string? search = null)
    {
        IQueryable<Customer> customersQuery = _context.Customers
            .Include(c => c.Users);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            customersQuery = customersQuery.Where(c =>
                c.Id.ToString().Contains(s) ||
                (c.Users != null && c.Users.Full_Name.Contains(s)));
        }

        var customers = await customersQuery
            .Select(c => new
            {
                c.Id,
                CustomerName = c.Users != null ? c.Users.Full_Name : $"Customer #{c.Id}"
            })
            .ToListAsync();

        if (customers.Count == 0)
        {
            return Ok(Array.Empty<TrustAccountBalanceDto>());
        }

        var customerIds = customers.Select(c => c.Id).ToList();
        var balanceRows = await _context.TrustLedgerEntries
            .Where(e => customerIds.Contains(e.CustomerId))
            .GroupBy(e => e.CustomerId)
            .Select(g => new
            {
                CustomerId = g.Key,
                CurrentBalance = g.Sum(e => (double?)((e.EntryType == TrustEntryTypes.Deposit || e.EntryType == TrustEntryTypes.AdjustmentIncrease) ? e.Amount : -e.Amount)) ?? 0,
                LastMovementDate = g.Max(e => (DateOnly?)e.OperationDate)
            })
            .ToDictionaryAsync(x => x.CustomerId, x => new { x.CurrentBalance, x.LastMovementDate });

        var result = customers
            .Select(c =>
            {
                var balance = balanceRows.GetValueOrDefault(c.Id);
                return new TrustAccountBalanceDto
                {
                    CustomerId = c.Id,
                    CustomerName = c.CustomerName,
                    CurrentBalance = balance?.CurrentBalance ?? 0,
                    LastMovementDate = balance?.LastMovementDate
                };
            })
            .OrderByDescending(x => x.CurrentBalance)
            .ThenBy(x => x.CustomerName)
            .ToList();

        return Ok(result);
    }

    [HttpGet("accounts/{customerId:int}/balance")]
    public async Task<ActionResult<TrustAccountBalanceDto>> GetCustomerBalance(int customerId, [FromQuery] DateOnly? asOfDate = null)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == customerId);

        if (customer is null)
        {
            return NotFound(new { message = "Customer not found" });
        }

        var balance = await GetBalanceAsync(customerId, asOfDate);
        var lastMovement = await _context.TrustLedgerEntries
            .Where(e => e.CustomerId == customerId)
            .MaxAsync(e => (DateOnly?)e.OperationDate);

        return Ok(new TrustAccountBalanceDto
        {
            CustomerId = customer.Id,
            CustomerName = customer.Users?.Full_Name ?? $"Customer #{customer.Id}",
            CurrentBalance = balance,
            LastMovementDate = lastMovement
        });
    }

    [HttpGet("accounts/{customerId:int}/ledger")]
    public async Task<ActionResult<IEnumerable<TrustLedgerEntryDto>>> GetCustomerLedger(int customerId, [FromQuery] DateOnly? fromDate = null, [FromQuery] DateOnly? toDate = null)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == customerId);

        if (customer is null)
        {
            return NotFound(new { message = "Customer not found" });
        }

        var result = await BuildCustomerLedgerAsync(
            customer.Id,
            customer.Users?.Full_Name ?? $"Customer #{customer.Id}",
            fromDate,
            toDate);
        return Ok(result);
    }

    [HttpGet("accounts/{customerId:int}/ledger/export")]
    public async Task<IActionResult> ExportCustomerLedger(
        int customerId,
        [FromQuery] string format = "csv",
        [FromQuery] DateOnly? fromDate = null,
        [FromQuery] DateOnly? toDate = null)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == customerId);

        if (customer is null)
        {
            return NotFound(new { message = "Customer not found" });
        }

        var customerName = customer.Users?.Full_Name ?? $"Customer #{customer.Id}";
        var ledgerRows = await BuildCustomerLedgerAsync(customer.Id, customerName, fromDate, toDate);
        var generatedAt = DateTime.UtcNow;

        if (string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase))
        {
            var lines = new List<string>
            {
                $"Generated: {generatedAt:yyyy-MM-dd HH:mm} UTC",
                $"Customer: {customerName} (#{customer.Id})",
                $"Range: {(fromDate.HasValue ? fromDate.Value.ToString("yyyy-MM-dd") : "Start")} -> {(toDate.HasValue ? toDate.Value.ToString("yyyy-MM-dd") : "End")}",
                $"Rows: {ledgerRows.Count}",
                $"Ending Balance: {(ledgerRows.LastOrDefault()?.RunningBalance ?? 0):F2}",
                ""
            };

            lines.AddRange(ledgerRows.Select(r =>
                $"{r.OperationDate:yyyy-MM-dd} | {r.EntryType} | {r.Amount:F2} | Bal={r.RunningBalance:F2} | Ref={r.Reference ?? "-"}"));

            var pdfBytes = ReportExportBuilder.BuildSimplePdf("Trust Ledger Report", lines);
            return File(pdfBytes, "application/pdf", $"trust-ledger-{customer.Id}-{generatedAt:yyyyMMddHHmm}.pdf");
        }

        var csvBytes = ReportExportBuilder.BuildCsv(
            new[] { "Id", "CustomerId", "CustomerName", "CaseCode", "EntryType", "Amount", "OperationDate", "RunningBalance", "Reference", "Description", "CreatedAt", "CreatedBy" },
            ledgerRows.Select(r => new[]
            {
                r.Id.ToString(),
                r.CustomerId.ToString(),
                r.CustomerName ?? string.Empty,
                r.CaseCode?.ToString() ?? string.Empty,
                r.EntryType,
                r.Amount.ToString("F2"),
                r.OperationDate.ToString("yyyy-MM-dd"),
                r.RunningBalance.ToString("F2"),
                r.Reference ?? string.Empty,
                r.Description ?? string.Empty,
                r.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                r.CreatedBy ?? string.Empty
            }));

        return File(csvBytes, "text/csv", $"trust-ledger-{customer.Id}-{generatedAt:yyyyMMddHHmm}.csv");
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("deposits")]
    public async Task<ActionResult<TrustLedgerEntryDto>> CreateDeposit([FromBody] CreateTrustDepositDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == dto.CustomerId);
        if (customer is null)
        {
            return BadRequest(new { message = "Customer not found" });
        }

        if (dto.CaseCode.HasValue)
        {
            var caseValidation = await ValidateCaseLinkAsync(dto.CustomerId, dto.CaseCode.Value);
            if (caseValidation is not null)
            {
                return caseValidation;
            }
        }

        var entity = new TrustLedgerEntry
        {
            CustomerId = dto.CustomerId,
            CaseCode = dto.CaseCode,
            EntryType = TrustEntryTypes.Deposit,
            Amount = dto.Amount,
            OperationDate = dto.OperationDate,
            Description = dto.Description,
            Reference = dto.Reference,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = HttpContext?.User?.Identity?.Name
        };

        _context.TrustLedgerEntries.Add(entity);
        await _context.SaveChangesAsync();

        var runningBalance = await GetBalanceAsync(dto.CustomerId, null);
        return Ok(MapLedgerEntry(entity, customer.Users?.Full_Name, runningBalance));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("withdrawals")]
    public async Task<ActionResult<TrustLedgerEntryDto>> CreateWithdrawal([FromBody] CreateTrustWithdrawalDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == dto.CustomerId);
        if (customer is null)
        {
            return BadRequest(new { message = "Customer not found" });
        }

        if (dto.CaseCode.HasValue)
        {
            var caseValidation = await ValidateCaseLinkAsync(dto.CustomerId, dto.CaseCode.Value);
            if (caseValidation is not null)
            {
                return caseValidation;
            }
        }

        var balanceAtOperationDate = await GetBalanceAsync(dto.CustomerId, dto.OperationDate);
        if (balanceAtOperationDate < dto.Amount)
        {
            return BadRequest(new
            {
                message = "Insufficient trust balance for this withdrawal.",
                available = balanceAtOperationDate,
                requested = dto.Amount
            });
        }

        var entity = new TrustLedgerEntry
        {
            CustomerId = dto.CustomerId,
            CaseCode = dto.CaseCode,
            EntryType = TrustEntryTypes.Withdrawal,
            Amount = dto.Amount,
            OperationDate = dto.OperationDate,
            Description = dto.Description,
            Reference = dto.Reference,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = HttpContext?.User?.Identity?.Name
        };

        _context.TrustLedgerEntries.Add(entity);
        await _context.SaveChangesAsync();

        var runningBalance = await GetBalanceAsync(dto.CustomerId, null);
        return Ok(MapLedgerEntry(entity, customer.Users?.Full_Name, runningBalance));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("adjustments")]
    public async Task<ActionResult<TrustLedgerEntryDto>> CreateAdjustment([FromBody] CreateTrustAdjustmentDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == dto.CustomerId);
        if (customer is null)
        {
            return BadRequest(new { message = "Customer not found" });
        }

        if (dto.CaseCode.HasValue)
        {
            var caseValidation = await ValidateCaseLinkAsync(dto.CustomerId, dto.CaseCode.Value);
            if (caseValidation is not null)
            {
                return caseValidation;
            }
        }

        var normalizedDirection = dto.Direction.Trim();
        var isIncrease = string.Equals(normalizedDirection, "Increase", StringComparison.OrdinalIgnoreCase);
        var entryType = isIncrease ? TrustEntryTypes.AdjustmentIncrease : TrustEntryTypes.AdjustmentDecrease;

        if (!isIncrease)
        {
            var balanceAtOperationDate = await GetBalanceAsync(dto.CustomerId, dto.OperationDate);
            if (balanceAtOperationDate < dto.Amount)
            {
                return BadRequest(new
                {
                    message = "Insufficient trust balance for a decrease adjustment.",
                    available = balanceAtOperationDate,
                    requested = dto.Amount
                });
            }
        }

        var entity = new TrustLedgerEntry
        {
            CustomerId = dto.CustomerId,
            CaseCode = dto.CaseCode,
            EntryType = entryType,
            Amount = dto.Amount,
            OperationDate = dto.OperationDate,
            Description = dto.Description,
            Reference = dto.Reference,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = HttpContext?.User?.Identity?.Name
        };

        _context.TrustLedgerEntries.Add(entity);
        await _context.SaveChangesAsync();

        var runningBalance = await GetBalanceAsync(dto.CustomerId, null);
        return Ok(MapLedgerEntry(entity, customer.Users?.Full_Name, runningBalance));
    }

    [HttpGet("summary")]
    public async Task<ActionResult<TrustSummaryDto>> GetSummary([FromQuery] DateOnly? asOfDate = null)
    {
        var asOf = asOfDate ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var balances = await _context.TrustLedgerEntries
            .Where(e => e.OperationDate <= asOf)
            .GroupBy(e => e.CustomerId)
            .Select(g => new
            {
                CustomerId = g.Key,
                Balance = g.Sum(e => (double?)((e.EntryType == TrustEntryTypes.Deposit || e.EntryType == TrustEntryTypes.AdjustmentIncrease) ? e.Amount : -e.Amount)) ?? 0
            })
            .ToListAsync();

        var totalClientLedgerBalance = balances.Sum(x => x.Balance);
        var activeAccounts = balances.Count(x => Math.Abs(x.Balance) > 0.000001d);
        var negativeAccounts = balances.Count(x => x.Balance < 0);

        var latestReconciliation = await _context.TrustReconciliations
            .OrderByDescending(r => r.ReconciliationDate)
            .ThenByDescending(r => r.Id)
            .Select(r => new TrustReconciliationDto
            {
                Id = r.Id,
                ReconciliationDate = r.ReconciliationDate,
                BankStatementBalance = r.BankStatementBalance,
                BookBalance = r.BookBalance,
                ClientLedgerBalance = r.ClientLedgerBalance,
                BankToBookDifference = r.BankToBookDifference,
                ClientToBookDifference = r.ClientToBookDifference,
                Notes = r.Notes,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy
            })
            .FirstOrDefaultAsync();

        return Ok(new TrustSummaryDto
        {
            AsOfDate = asOf,
            BookBalance = totalClientLedgerBalance,
            TotalClientLedgerBalance = totalClientLedgerBalance,
            ActiveClientAccounts = activeAccounts,
            NegativeBalanceAccounts = negativeAccounts,
            LatestReconciliation = latestReconciliation
        });
    }

    [HttpGet("reports/monthly-trends")]
    public async Task<ActionResult<TrustMonthlyTrendsReportDto>> GetMonthlyTrends(
        [FromQuery] int months = 12,
        [FromQuery] int? customerId = null,
        [FromQuery] DateOnly? toDate = null)
    {
        var windowMonths = Math.Clamp(months, 3, 24);
        var endDate = toDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var startMonth = new DateOnly(endDate.Year, endDate.Month, 1).AddMonths(-(windowMonths - 1));

        string? customerName = null;
        if (customerId.HasValue)
        {
            var customer = await _context.Customers
                .Include(c => c.Users)
                .FirstOrDefaultAsync(c => c.Id == customerId.Value);

            if (customer is null)
            {
                return NotFound(new { message = "Customer not found" });
            }

            customerName = customer.Users?.Full_Name ?? $"Customer #{customer.Id}";
        }

        var openingQuery = _context.TrustLedgerEntries.Where(e => e.OperationDate < startMonth);
        if (customerId.HasValue)
        {
            openingQuery = openingQuery.Where(e => e.CustomerId == customerId.Value);
        }

        var openingBalance = await openingQuery
            .SumAsync(e => (double?)SignedAmount(e.EntryType, e.Amount)) ?? 0;

        var monthlyLedgerQuery = _context.TrustLedgerEntries
            .Where(e => e.OperationDate >= startMonth && e.OperationDate <= endDate);
        if (customerId.HasValue)
        {
            monthlyLedgerQuery = monthlyLedgerQuery.Where(e => e.CustomerId == customerId.Value);
        }

        var monthlyAggregates = await monthlyLedgerQuery
            .GroupBy(e => new { e.OperationDate.Year, e.OperationDate.Month })
            .Select(g => new
            {
                g.Key.Year,
                g.Key.Month,
                Deposits = g.Where(e => e.EntryType == TrustEntryTypes.Deposit || e.EntryType == TrustEntryTypes.AdjustmentIncrease)
                    .Sum(e => (double?)e.Amount) ?? 0,
                Withdrawals = g.Where(e => e.EntryType == TrustEntryTypes.Withdrawal || e.EntryType == TrustEntryTypes.AdjustmentDecrease)
                    .Sum(e => (double?)e.Amount) ?? 0
            })
            .ToListAsync();

        var monthlyMap = monthlyAggregates.ToDictionary(
            x => $"{x.Year:D4}-{x.Month:D2}",
            x => new { x.Deposits, x.Withdrawals });

        var monthlyPoints = new List<TrustMonthlyTrendPointDto>(windowMonths);
        var runningBalance = openingBalance;
        for (var i = 0; i < windowMonths; i++)
        {
            var cursor = startMonth.AddMonths(i);
            var key = $"{cursor.Year:D4}-{cursor.Month:D2}";
            var monthly = monthlyMap.GetValueOrDefault(key);
            var deposits = monthly?.Deposits ?? 0;
            var withdrawals = monthly?.Withdrawals ?? 0;
            var net = deposits - withdrawals;
            runningBalance += net;

            monthlyPoints.Add(new TrustMonthlyTrendPointDto
            {
                Year = cursor.Year,
                Month = cursor.Month,
                Deposits = deposits,
                Withdrawals = withdrawals,
                NetFlow = net,
                EndingBalance = runningBalance
            });
        }

        var reconciliationRows = await BuildReconciliationsQuery(startMonth, endDate)
            .GroupBy(r => new { r.ReconciliationDate.Year, r.ReconciliationDate.Month })
            .Select(g => new
            {
                g.Key.Year,
                g.Key.Month,
                Count = g.Count(),
                AverageBankToBookDifference = g.Average(x => x.BankToBookDifference),
                MaxAbsoluteBankToBookDifference = g.Max(x => Math.Abs(x.BankToBookDifference))
            })
            .ToListAsync();

        var reconciliationMap = reconciliationRows.ToDictionary(
            x => $"{x.Year:D4}-{x.Month:D2}",
            x => x);

        var reconciliationPoints = new List<TrustReconciliationTrendPointDto>(windowMonths);
        for (var i = 0; i < windowMonths; i++)
        {
            var cursor = startMonth.AddMonths(i);
            var key = $"{cursor.Year:D4}-{cursor.Month:D2}";
            var monthValue = reconciliationMap.GetValueOrDefault(key);
            reconciliationPoints.Add(new TrustReconciliationTrendPointDto
            {
                Year = cursor.Year,
                Month = cursor.Month,
                Count = monthValue?.Count ?? 0,
                AverageBankToBookDifference = monthValue?.AverageBankToBookDifference ?? 0,
                MaxAbsoluteBankToBookDifference = monthValue?.MaxAbsoluteBankToBookDifference ?? 0
            });
        }

        return Ok(new TrustMonthlyTrendsReportDto
        {
            Months = windowMonths,
            FromMonth = startMonth,
            ToDate = endDate,
            CustomerId = customerId,
            CustomerName = customerName,
            TotalDeposits = monthlyPoints.Sum(x => x.Deposits),
            TotalWithdrawals = monthlyPoints.Sum(x => x.Withdrawals),
            NetFlow = monthlyPoints.Sum(x => x.NetFlow),
            OpeningBalance = openingBalance,
            EndingBalance = monthlyPoints.LastOrDefault()?.EndingBalance ?? openingBalance,
            MonthlyPoints = monthlyPoints,
            ReconciliationPoints = reconciliationPoints
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("reconciliations")]
    public async Task<ActionResult<TrustReconciliationDto>> CreateReconciliation([FromBody] CreateTrustReconciliationDto dto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var clientLedgerBalance = await _context.TrustLedgerEntries
            .Where(e => e.OperationDate <= dto.ReconciliationDate)
            .SumAsync(e => (double?)((e.EntryType == TrustEntryTypes.Deposit || e.EntryType == TrustEntryTypes.AdjustmentIncrease) ? e.Amount : -e.Amount)) ?? 0;

        var reconciliation = new TrustReconciliation
        {
            ReconciliationDate = dto.ReconciliationDate,
            BankStatementBalance = dto.BankStatementBalance,
            BookBalance = clientLedgerBalance,
            ClientLedgerBalance = clientLedgerBalance,
            BankToBookDifference = Math.Round(dto.BankStatementBalance - clientLedgerBalance, 2),
            ClientToBookDifference = 0,
            Notes = dto.Notes,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = HttpContext?.User?.Identity?.Name
        };

        _context.TrustReconciliations.Add(reconciliation);
        await _context.SaveChangesAsync();

        return Ok(MapReconciliation(reconciliation));
    }

    [HttpGet("reconciliations")]
    public async Task<ActionResult<PagedResult<TrustReconciliationDto>>> GetReconciliations(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        [FromQuery] DateOnly? fromDate = null,
        [FromQuery] DateOnly? toDate = null)
    {
        var p = Math.Max(1, page);
        var ps = Math.Clamp(pageSize, 1, 200);

        var query = BuildReconciliationsQuery(fromDate, toDate);
        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(r => r.ReconciliationDate)
            .ThenByDescending(r => r.Id)
            .Skip((p - 1) * ps)
            .Take(ps)
            .Select(r => new TrustReconciliationDto
            {
                Id = r.Id,
                ReconciliationDate = r.ReconciliationDate,
                BankStatementBalance = r.BankStatementBalance,
                BookBalance = r.BookBalance,
                ClientLedgerBalance = r.ClientLedgerBalance,
                BankToBookDifference = r.BankToBookDifference,
                ClientToBookDifference = r.ClientToBookDifference,
                Notes = r.Notes,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy
            })
            .ToListAsync();

        return Ok(new PagedResult<TrustReconciliationDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = p,
            PageSize = ps
        });
    }

    [HttpGet("reconciliations/export")]
    public async Task<IActionResult> ExportReconciliations(
        [FromQuery] string format = "csv",
        [FromQuery] DateOnly? fromDate = null,
        [FromQuery] DateOnly? toDate = null)
    {
        var generatedAt = DateTime.UtcNow;
        var rows = await BuildReconciliationsQuery(fromDate, toDate)
            .OrderByDescending(r => r.ReconciliationDate)
            .ThenByDescending(r => r.Id)
            .Select(r => new TrustReconciliationDto
            {
                Id = r.Id,
                ReconciliationDate = r.ReconciliationDate,
                BankStatementBalance = r.BankStatementBalance,
                BookBalance = r.BookBalance,
                ClientLedgerBalance = r.ClientLedgerBalance,
                BankToBookDifference = r.BankToBookDifference,
                ClientToBookDifference = r.ClientToBookDifference,
                Notes = r.Notes,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy
            })
            .ToListAsync();

        if (string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase))
        {
            var lines = new List<string>
            {
                $"Generated: {generatedAt:yyyy-MM-dd HH:mm} UTC",
                $"Range: {(fromDate.HasValue ? fromDate.Value.ToString("yyyy-MM-dd") : "Start")} -> {(toDate.HasValue ? toDate.Value.ToString("yyyy-MM-dd") : "End")}",
                $"Rows: {rows.Count}",
                ""
            };

            lines.AddRange(rows.Select(r =>
                $"{r.ReconciliationDate:yyyy-MM-dd} | Bank={r.BankStatementBalance:F2} | Book={r.BookBalance:F2} | Diff={r.BankToBookDifference:F2}"));

            var pdfBytes = ReportExportBuilder.BuildSimplePdf("Trust Reconciliations Report", lines);
            return File(pdfBytes, "application/pdf", $"trust-reconciliations-{generatedAt:yyyyMMddHHmm}.pdf");
        }

        var csvBytes = ReportExportBuilder.BuildCsv(
            new[] { "Id", "ReconciliationDate", "BankStatementBalance", "BookBalance", "ClientLedgerBalance", "BankToBookDifference", "ClientToBookDifference", "Notes", "CreatedAt", "CreatedBy" },
            rows.Select(r => new[]
            {
                r.Id.ToString(),
                r.ReconciliationDate.ToString("yyyy-MM-dd"),
                r.BankStatementBalance.ToString("F2"),
                r.BookBalance.ToString("F2"),
                r.ClientLedgerBalance.ToString("F2"),
                r.BankToBookDifference.ToString("F2"),
                r.ClientToBookDifference.ToString("F2"),
                r.Notes ?? string.Empty,
                r.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                r.CreatedBy ?? string.Empty
            }));

        return File(csvBytes, "text/csv", $"trust-reconciliations-{generatedAt:yyyyMMddHHmm}.csv");
    }

    [HttpGet("reconciliations/{id:long}")]
    public async Task<ActionResult<TrustReconciliationDto>> GetReconciliation(long id)
    {
        var item = await _context.TrustReconciliations
            .Where(r => r.Id == id)
            .Select(r => new TrustReconciliationDto
            {
                Id = r.Id,
                ReconciliationDate = r.ReconciliationDate,
                BankStatementBalance = r.BankStatementBalance,
                BookBalance = r.BookBalance,
                ClientLedgerBalance = r.ClientLedgerBalance,
                BankToBookDifference = r.BankToBookDifference,
                ClientToBookDifference = r.ClientToBookDifference,
                Notes = r.Notes,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy
            })
            .FirstOrDefaultAsync();

        if (item is null)
        {
            return NotFound(new { message = "Reconciliation not found" });
        }

        return Ok(item);
    }

    private async Task<ActionResult?> ValidateCaseLinkAsync(int customerId, int caseCode)
    {
        var caseExists = await _context.Cases.AnyAsync(c => c.Code == caseCode);
        if (!caseExists)
        {
            return BadRequest(new { message = "Case not found" });
        }

        var caseLinkedToCustomer = await _context.Custmors_Cases
            .AnyAsync(cc => cc.Custmors_Id == customerId && cc.Case_Id == caseCode);
        if (!caseLinkedToCustomer)
        {
            return BadRequest(new { message = "Case is not linked to the selected customer." });
        }

        return null;
    }

    private async Task<double> GetBalanceAsync(int customerId, DateOnly? asOfDate)
    {
        var query = _context.TrustLedgerEntries.Where(e => e.CustomerId == customerId);
        if (asOfDate.HasValue)
        {
            query = query.Where(e => e.OperationDate <= asOfDate.Value);
        }

        return await query.SumAsync(e => (double?)((e.EntryType == TrustEntryTypes.Deposit || e.EntryType == TrustEntryTypes.AdjustmentIncrease) ? e.Amount : -e.Amount)) ?? 0;
    }

    private async Task<List<TrustLedgerEntryDto>> BuildCustomerLedgerAsync(int customerId, string customerName, DateOnly? fromDate, DateOnly? toDate)
    {
        var lowerBoundDate = fromDate ?? DateOnly.MinValue;
        var upperBoundDate = toDate ?? DateOnly.MaxValue;

        var openingBalance = fromDate.HasValue
            ? await GetBalanceAsync(customerId, fromDate.Value.AddDays(-1))
            : 0;
        var entries = await _context.TrustLedgerEntries
            .Where(e => e.CustomerId == customerId && e.OperationDate >= lowerBoundDate && e.OperationDate <= upperBoundDate)
            .OrderBy(e => e.OperationDate)
            .ThenBy(e => e.Id)
            .ToListAsync();

        var running = openingBalance;
        var result = new List<TrustLedgerEntryDto>(entries.Count);
        foreach (var entry in entries)
        {
            running += SignedAmount(entry.EntryType, entry.Amount);
            result.Add(new TrustLedgerEntryDto
            {
                Id = entry.Id,
                CustomerId = entry.CustomerId,
                CustomerName = customerName,
                CaseCode = entry.CaseCode,
                EntryType = entry.EntryType,
                Amount = entry.Amount,
                OperationDate = entry.OperationDate,
                Description = entry.Description,
                Reference = entry.Reference,
                CreatedAt = entry.CreatedAt,
                CreatedBy = entry.CreatedBy,
                RunningBalance = running
            });
        }

        return result;
    }

    private IQueryable<TrustReconciliation> BuildReconciliationsQuery(DateOnly? fromDate, DateOnly? toDate)
    {
        var query = _context.TrustReconciliations.AsQueryable();
        if (fromDate.HasValue)
        {
            query = query.Where(r => r.ReconciliationDate >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            query = query.Where(r => r.ReconciliationDate <= toDate.Value);
        }

        return query;
    }

    private static double SignedAmount(string entryType, double amount)
    {
        return entryType switch
        {
            TrustEntryTypes.Deposit => amount,
            TrustEntryTypes.AdjustmentIncrease => amount,
            TrustEntryTypes.Withdrawal => -amount,
            TrustEntryTypes.AdjustmentDecrease => -amount,
            _ => 0
        };
    }

    private static TrustLedgerEntryDto MapLedgerEntry(TrustLedgerEntry entry, string? customerName, double runningBalance)
    {
        return new TrustLedgerEntryDto
        {
            Id = entry.Id,
            CustomerId = entry.CustomerId,
            CustomerName = customerName,
            CaseCode = entry.CaseCode,
            EntryType = entry.EntryType,
            Amount = entry.Amount,
            OperationDate = entry.OperationDate,
            Description = entry.Description,
            Reference = entry.Reference,
            CreatedAt = entry.CreatedAt,
            CreatedBy = entry.CreatedBy,
            RunningBalance = runningBalance
        };
    }

    private static TrustReconciliationDto MapReconciliation(TrustReconciliation reconciliation)
    {
        return new TrustReconciliationDto
        {
            Id = reconciliation.Id,
            ReconciliationDate = reconciliation.ReconciliationDate,
            BankStatementBalance = reconciliation.BankStatementBalance,
            BookBalance = reconciliation.BookBalance,
            ClientLedgerBalance = reconciliation.ClientLedgerBalance,
            BankToBookDifference = reconciliation.BankToBookDifference,
            ClientToBookDifference = reconciliation.ClientToBookDifference,
            Notes = reconciliation.Notes,
            CreatedAt = reconciliation.CreatedAt,
            CreatedBy = reconciliation.CreatedBy
        };
    }
}
