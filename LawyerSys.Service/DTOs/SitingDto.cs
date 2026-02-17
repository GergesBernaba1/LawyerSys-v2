using System.ComponentModel.DataAnnotations;

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
    [Required]
    public DateTime SitingTime { get; set; }

    [Required]
    public DateOnly SitingDate { get; set; }

    [Required]
    public DateTime SitingNotification { get; set; }

    [Required]
    [MaxLength(200)]
    public string JudgeName { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Notes { get; set; }
}

public class UpdateSitingDto
{
    public DateTime? SitingTime { get; set; }
    public DateOnly? SitingDate { get; set; }
    public DateTime? SitingNotification { get; set; }

    [MaxLength(200)]
    public string? JudgeName { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }
}
