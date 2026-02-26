namespace LawyerSys.DTOs;

public class AdministrationOverviewDto
{
    public AdministrationCountsDto Counts { get; set; } = new();
    public List<AdministrationModuleDto> Modules { get; set; } = new();
}

public class AdministrationCountsDto
{
    public int Users { get; set; }
    public int Employees { get; set; }
    public int Customers { get; set; }
    public int Cases { get; set; }
    public int Hearings { get; set; }
    public int Tasks { get; set; }
    public int OverdueTasks { get; set; }
    public int AuditLogs { get; set; }
}

public class AdministrationModuleDto
{
    public string Key { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string ApiPath { get; set; } = string.Empty;
    public bool CanView { get; set; }
    public bool CanCreateOrUpdate { get; set; }
}
