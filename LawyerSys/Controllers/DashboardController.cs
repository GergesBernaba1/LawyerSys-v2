using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public DashboardController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("analytics")]
    public async Task<ActionResult<DashboardAnalyticsDto>> GetAnalytics()
    {
        var now = DateTime.Now;
        var today = DateOnly.FromDateTime(now);

        var currentMonthStart = new DateOnly(today.Year, today.Month, 1);
        var nextMonthStart = currentMonthStart.AddMonths(1);
        var lastMonthStart = currentMonthStart.AddMonths(-1);

        var totals = new DashboardTotalsDto
        {
            Cases = await _context.Cases.CountAsync(),
            Customers = await _context.Customers.CountAsync(),
            Employees = await _context.Employees.CountAsync(),
            Files = await _context.Files.CountAsync(),
        };

        var casesThisMonth = await _context.Cases.CountAsync(c => c.Invition_Date >= currentMonthStart && c.Invition_Date < nextMonthStart);
        var casesLastMonth = await _context.Cases.CountAsync(c => c.Invition_Date >= lastMonthStart && c.Invition_Date < currentMonthStart);

        var receiptsThisMonth = await _context.Billing_Receipts
            .Where(r => r.Date_Of_Opreation >= currentMonthStart && r.Date_Of_Opreation < nextMonthStart)
            .SumAsync(r => (double?)r.Amount) ?? 0;
        var paymentsThisMonth = await _context.Billing_Pays
            .Where(p => p.Date_Of_Opreation >= currentMonthStart && p.Date_Of_Opreation < nextMonthStart)
            .SumAsync(p => (double?)p.Amount) ?? 0;

        var receiptsLastMonth = await _context.Billing_Receipts
            .Where(r => r.Date_Of_Opreation >= lastMonthStart && r.Date_Of_Opreation < currentMonthStart)
            .SumAsync(r => (double?)r.Amount) ?? 0;
        var paymentsLastMonth = await _context.Billing_Pays
            .Where(p => p.Date_Of_Opreation >= lastMonthStart && p.Date_Of_Opreation < currentMonthStart)
            .SumAsync(p => (double?)p.Amount) ?? 0;

        var revenueThisMonth = receiptsThisMonth - paymentsThisMonth;
        var revenueLastMonth = receiptsLastMonth - paymentsLastMonth;

        var upcomingHearings = await _context.Sitings.CountAsync(s => s.Siting_Time >= now && s.Siting_Time <= now.AddDays(7));
        var overdueTasks = await _context.AdminstrativeTasks.CountAsync(t => t.Task_Reminder_Date < now);

        var result = new DashboardAnalyticsDto
        {
            Totals = totals,
            Trends = new DashboardTrendsDto
            {
                CasesThisMonth = casesThisMonth,
                CasesLastMonth = casesLastMonth,
                CasesChangePercent = CalculateChangePercent(casesLastMonth, casesThisMonth),
                RevenueThisMonth = revenueThisMonth,
                RevenueLastMonth = revenueLastMonth,
                RevenueChangePercent = CalculateChangePercent(revenueLastMonth, revenueThisMonth)
            },
            Alerts = new DashboardAlertsDto
            {
                UpcomingHearings = upcomingHearings,
                OverdueTasks = overdueTasks
            }
        };

        return Ok(result);
    }

    private static double CalculateChangePercent(double previous, double current)
    {
        if (previous == 0)
            return current == 0 ? 0 : 100;

        return Math.Round(((current - previous) / Math.Abs(previous)) * 100, 2);
    }
}
