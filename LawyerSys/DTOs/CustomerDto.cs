using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class CustomerDto
{
    public int Id { get; set; }
    public int UsersId { get; set; }
    public LegacyUserDto? User { get; set; }
    // Identity information (if an ApplicationUser was created for this customer)
    public IdentityUserInfoDto? Identity { get; set; }
}

public class IdentityUserInfoDto
{
    public string Id { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public bool EmailConfirmed { get; set; }
    public bool RequiresPasswordReset { get; set; }
}

public class CreateCustomerDto
{
    [Range(1, int.MaxValue)]
    public int UsersId { get; set; }
}

public class CreateCustomerWithUserDto
{
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

public class CustomerProfileDto
{
    public int Id { get; set; }
    public LegacyUserDto? User { get; set; }
    public IdentityUserInfoDto? Identity { get; set; }
    public List<CaseWithEmployeeDto> Cases { get; set; } = new();
}

public class CaseWithEmployeeDto
{
    public int CaseId { get; set; }
    public string CaseName { get; set; } = string.Empty;
    public int Code { get; set; }
    public LegacyUserDto? AssignedEmployee { get; set; }
}

public class UpdateCustomerDto
{
    [Range(1, int.MaxValue)]
    public int? UsersId { get; set; }
}
