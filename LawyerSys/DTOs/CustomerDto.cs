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
    public int UsersId { get; set; }
}

public class CreateCustomerWithUserDto
{
    public string FullName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? Email { get; set; }
    public string Job { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string SSN { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
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
    public int? UsersId { get; set; }
}
