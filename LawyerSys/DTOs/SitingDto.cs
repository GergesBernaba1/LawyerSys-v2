namespace LawyerSys.DTOs;

// Siting (Hearing) DTOs
public class SitingDto
{
    public int Id { get; set; }
    public DateTime SitingTime { get; set; }
    public DateOnly SitingDate { get; set; }
    public DateTime SitingNotification { get; set; }
    public string JudgeName { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
}

public class CreateSitingDto
{
    public DateTime SitingTime { get; set; }
    public DateOnly SitingDate { get; set; }
    public DateTime SitingNotification { get; set; }
    public string JudgeName { get; set; } = string.Empty;
    public string? Notes { get; set; }
}

public class UpdateSitingDto
{
    public DateTime? SitingTime { get; set; }
    public DateOnly? SitingDate { get; set; }
    public DateTime? SitingNotification { get; set; }
    public string? JudgeName { get; set; }
    public string? Notes { get; set; }
}
