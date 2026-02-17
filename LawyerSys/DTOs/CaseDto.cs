using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public enum CaseStatus
{
    New = 0,
    InProgress = 1,
    AwaitingHearing = 2,
    Closed = 3,
    Won = 4,
    Lost = 5
}

public class CaseDto
{
    public int Id { get; set; }
    public int Code { get; set; }
    public string InvitionsStatment { get; set; } = string.Empty;
    public string InvitionType { get; set; } = string.Empty;
    public DateOnly InvitionDate { get; set; }
    public int TotalAmount { get; set; }
    public string Notes { get; set; } = string.Empty;
    public CaseStatus Status { get; set; } = CaseStatus.New;
}

public class CaseStatusHistoryDto
{
    public int Id { get; set; }
    public int CaseId { get; set; }
    public CaseStatus OldStatus { get; set; }
    public CaseStatus NewStatus { get; set; }
    public string? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; }
}

public class ChangeCaseStatusDto
{
    // Accept either status name (e.g. "InProgress") or numeric value
    [Required]
    [MaxLength(50)]
    public string Status { get; set; } = string.Empty;
}

public class CreateCaseDto
{
    [Range(1, int.MaxValue)]
    public int Code { get; set; }

    [Required]
    [MaxLength(4000)]
    public string InvitionsStatment { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string InvitionType { get; set; } = string.Empty;

    [Required]
    public DateOnly InvitionDate { get; set; }

    [Range(0, int.MaxValue)]
    public int TotalAmount { get; set; }

    [MaxLength(4000)]
    public string? Notes { get; set; }
}

public class UpdateCaseDto
{
    [MaxLength(4000)]
    public string? InvitionsStatment { get; set; }

    [MaxLength(200)]
    public string? InvitionType { get; set; }

    public DateOnly? InvitionDate { get; set; }

    [Range(0, int.MaxValue)]
    public int? TotalAmount { get; set; }

    [MaxLength(4000)]
    public string? Notes { get; set; }
}

public class AssignEmployeeDto
{
    [Range(1, int.MaxValue)]
    public int EmployeeId { get; set; }
}

public class CaseAssignmentDto
{
    public int CaseCode { get; set; }
    public int EmployeeId { get; set; }
    public LegacyUserDto? Employee { get; set; }
}
