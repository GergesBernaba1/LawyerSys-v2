using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

// Administrative Task DTOs
public class AdminTaskDto
{
    public int Id { get; set; }
    public string TaskName { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateOnly TaskDate { get; set; }
    public DateTime TaskReminderDate { get; set; }
    public string Notes { get; set; } = string.Empty;
    public int? EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
}

public class CreateAdminTaskDto
{
    [Required]
    [MaxLength(200)]
    public string TaskName { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Type { get; set; } = string.Empty;

    [Required]
    public DateOnly TaskDate { get; set; }

    [Required]
    public DateTime TaskReminderDate { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
    public int? EmployeeId { get; set; }
}

public class UpdateAdminTaskDto
{
    [MaxLength(200)]
    public string? TaskName { get; set; }

    [MaxLength(100)]
    public string? Type { get; set; }

    public DateOnly? TaskDate { get; set; }
    public DateTime? TaskReminderDate { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
    public int? EmployeeId { get; set; }
}
