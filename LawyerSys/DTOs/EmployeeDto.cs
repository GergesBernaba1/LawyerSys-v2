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
    public int Salary { get; set; }
    public int UsersId { get; set; }
}

public class CreateEmployeeWithUserDto
{
    public int Salary { get; set; }
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

public class UpdateEmployeeDto
{
    public int? Salary { get; set; }
}
