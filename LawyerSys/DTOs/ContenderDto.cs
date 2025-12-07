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
    public string FullName { get; set; } = string.Empty;
    public string SSN { get; set; } = string.Empty;
    public DateOnly BirthDate { get; set; }
    public bool? Type { get; set; }
}

public class UpdateContenderDto
{
    public string? FullName { get; set; }
    public string? SSN { get; set; }
    public DateOnly? BirthDate { get; set; }
    public bool? Type { get; set; }
}
