using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class IntakeLeadDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string? NationalId { get; set; }
    public string Subject { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? DesiredCaseType { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? QualificationNotes { get; set; }
    public bool ConflictChecked { get; set; }
    public bool HasConflict { get; set; }
    public string? ConflictDetails { get; set; }
    public int? AssignedEmployeeId { get; set; }
    public string? AssignedEmployeeName { get; set; }
    public DateTime? NextFollowUpAt { get; set; }
    public DateTime? AssignedAt { get; set; }
    public int? ConvertedCustomerId { get; set; }
    public int? ConvertedCaseCode { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class IntakeAssignmentOptionDto
{
    public int EmployeeId { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class CreatePublicIntakeLeadDto
{
    [Required]
    [MaxLength(120)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(256)]
    public string? Email { get; set; }

    [MaxLength(32)]
    public string? PhoneNumber { get; set; }

    [MaxLength(32)]
    public string? NationalId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Subject { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Description { get; set; }

    [MaxLength(80)]
    public string? DesiredCaseType { get; set; }
}

public class QualifyIntakeLeadDto
{
    [Required]
    public bool IsQualified { get; set; }

    [MaxLength(1024)]
    public string? Notes { get; set; }
}

public class ConvertIntakeLeadDto
{
    [MaxLength(80)]
    public string? CaseType { get; set; }

    [Range(0, int.MaxValue)]
    public int? InitialAmount { get; set; }
}

public class AssignIntakeLeadDto
{
    [Range(1, int.MaxValue)]
    public int AssignedEmployeeId { get; set; }

    public DateTime? NextFollowUpAt { get; set; }
}

public class IntakeConflictCheckDto
{
    public bool HasConflict { get; set; }
    public string Details { get; set; } = string.Empty;
}
