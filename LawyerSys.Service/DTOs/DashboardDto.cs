namespace LawyerSys.DTOs;

public class DashboardAnalyticsDto
{
    public DashboardTotalsDto Totals { get; set; } = new();
    public DashboardTrendsDto Trends { get; set; } = new();
    public DashboardAlertsDto Alerts { get; set; } = new();
}

public class DashboardTotalsDto
{
    public int Cases { get; set; }
    public int Customers { get; set; }
    public int Employees { get; set; }
    public int Files { get; set; }
}

public class DashboardTrendsDto
{
    public int CasesThisMonth { get; set; }
    public int CasesLastMonth { get; set; }
    public double CasesChangePercent { get; set; }
    public double RevenueThisMonth { get; set; }
    public double RevenueLastMonth { get; set; }
    public double RevenueChangePercent { get; set; }
}

public class DashboardAlertsDto
{
    public int UpcomingHearings { get; set; }
    public int OverdueTasks { get; set; }
}
