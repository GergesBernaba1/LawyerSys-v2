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
    public string TaskName { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateOnly TaskDate { get; set; }
    public DateTime TaskReminderDate { get; set; }
    public string? Notes { get; set; }
    public int? EmployeeId { get; set; }
}

public class UpdateAdminTaskDto
{
    public string? TaskName { get; set; }
    public string? Type { get; set; }
    public DateOnly? TaskDate { get; set; }
    public DateTime? TaskReminderDate { get; set; }
    public string? Notes { get; set; }
    public int? EmployeeId { get; set; }
}
