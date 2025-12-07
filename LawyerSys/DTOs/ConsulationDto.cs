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
    public string ConsultionState { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Subject { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? Feedback { get; set; }
    public string? Notes { get; set; }
    public DateTime DateTime { get; set; }
}

public class UpdateConsulationDto
{
    public string? ConsultionState { get; set; }
    public string? Type { get; set; }
    public string? Subject { get; set; }
    public string? Description { get; set; }
    public string? Feedback { get; set; }
    public string? Notes { get; set; }
    public DateTime? DateTime { get; set; }
}
