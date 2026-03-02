using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

// Contender DTOs
public class ContenderDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string SSN { get; set; } = string.Empty;
    public DateOnly BirthDate { get; set; }
    public bool? Type { get; set; }
}

public class CreateContenderDto
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    public string SSN { get; set; } = string.Empty;

    [Required]
    public DateOnly BirthDate { get; set; }
    public bool? Type { get; set; }
}

public class UpdateContenderDto
{
    [MaxLength(200)]
    public string? FullName { get; set; }

    public string? SSN { get; set; }

    public DateOnly? BirthDate { get; set; }
    public bool? Type { get; set; }
}
