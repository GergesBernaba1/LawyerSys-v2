namespace LawyerSys.DTOs;

public class CustomerDto
{
    public int Id { get; set; }
    public int UsersId { get; set; }
    public LegacyUserDto? User { get; set; }
}

public class CreateCustomerDto
{
    public int UsersId { get; set; }
}

public class CreateCustomerWithUserDto
{
    public string FullName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string Job { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string SSN { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class UpdateCustomerDto
{
    public int? UsersId { get; set; }
}
