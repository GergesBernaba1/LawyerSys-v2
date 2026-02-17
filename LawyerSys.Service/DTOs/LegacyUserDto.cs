using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class LegacyUserDto
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string Job { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string SSN { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
}

public class CreateLegacyUserDto
{
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(400)]
    public string? Address { get; set; }

    [Required]
    [MaxLength(100)]
    public string Job { get; set; } = string.Empty;

    [Required]
    [RegularExpression(@"^\d{7,20}$", ErrorMessage = "Phone number must contain 7 to 20 digits.")]
    public string PhoneNumber { get; set; } = string.Empty;

    [Required]
    public DateOnly DateOfBirth { get; set; }

    [Required]
    [RegularExpression(@"^\d{6,20}$", ErrorMessage = "SSN must contain 6 to 20 digits.")]
    public string SSN { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string UserName { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    [MaxLength(128)]
    public string Password { get; set; } = string.Empty;
}

public class UpdateLegacyUserDto
{
    [MaxLength(200)]
    public string? FullName { get; set; }

    [MaxLength(400)]
    public string? Address { get; set; }

    [MaxLength(100)]
    public string? Job { get; set; }

    [RegularExpression(@"^\d{7,20}$", ErrorMessage = "Phone number must contain 7 to 20 digits.")]
    public string? PhoneNumber { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    [RegularExpression(@"^\d{6,20}$", ErrorMessage = "SSN must contain 6 to 20 digits.")]
    public string? SSN { get; set; }
}
