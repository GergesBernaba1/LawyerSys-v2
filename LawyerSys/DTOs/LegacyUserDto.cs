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
    public string FullName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string Job { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public string SSN { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class UpdateLegacyUserDto
{
    public string? FullName { get; set; }
    public string? Address { get; set; }
    public string? Job { get; set; }
    public string? PhoneNumber { get; set; }
    public DateOnly? DateOfBirth { get; set; }
    public string? SSN { get; set; }
}
