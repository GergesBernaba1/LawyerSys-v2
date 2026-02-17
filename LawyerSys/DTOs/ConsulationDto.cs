using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

// Consultation DTOs
public class ConsulationDto
{
    public int Id { get; set; }
    public string ConsultionState { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Feedback { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public DateTime DateTime { get; set; }
}

public class CreateConsulationDto
{
    [Required]
    [MaxLength(100)]
    public string ConsultionState { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Type { get; set; } = string.Empty;

    [Required]
    [MaxLength(300)]
    public string Subject { get; set; } = string.Empty;

    [Required]
    [MaxLength(4000)]
    public string Description { get; set; } = string.Empty;

    [MaxLength(4000)]
    public string? Feedback { get; set; }

    [MaxLength(4000)]
    public string? Notes { get; set; }

    [Required]
    public DateTime DateTime { get; set; }
}

public class UpdateConsulationDto
{
    [MaxLength(100)]
    public string? ConsultionState { get; set; }

    [MaxLength(100)]
    public string? Type { get; set; }

    [MaxLength(300)]
    public string? Subject { get; set; }

    [MaxLength(4000)]
    public string? Description { get; set; }

    [MaxLength(4000)]
    public string? Feedback { get; set; }

    [MaxLength(4000)]
    public string? Notes { get; set; }

    public DateTime? DateTime { get; set; }
}
