using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class EmployeeDto
{
    public int Id { get; set; }
    public int Salary { get; set; }
    public int UsersId { get; set; }
    public LegacyUserDto? User { get; set; }
    // Identity information (if an ApplicationUser was created for this employee)
    public IdentityUserInfoDto? Identity { get; set; }
}

public class CreateEmployeeDto
{
    [Range(0, int.MaxValue)]
    public int Salary { get; set; }

    [Range(1, int.MaxValue)]
    public int UsersId { get; set; }
}

public class CreateEmployeeWithUserDto
{
    [Range(0, int.MaxValue)]
    public int Salary { get; set; }

    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(400)]
    public string? Address { get; set; }

    [EmailAddress]
    [MaxLength(256)]
    public string? Email { get; set; }

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

    [MaxLength(100)]
    public string UserName { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    [MaxLength(128)]
    public string Password { get; set; } = string.Empty;
}

public class UpdateEmployeeDto
{
    [Range(0, int.MaxValue)]
    public int? Salary { get; set; }
}
