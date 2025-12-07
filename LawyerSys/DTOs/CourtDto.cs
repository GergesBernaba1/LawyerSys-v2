namespace LawyerSys.DTOs;

// Court DTOs
public class CourtDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Telephone { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public int GovId { get; set; }
    public string? GovernmentName { get; set; }
}

public class CreateCourtDto
{
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Telephone { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public int GovId { get; set; }
}

public class UpdateCourtDto
{
    public string? Name { get; set; }
    public string? Address { get; set; }
    public string? Telephone { get; set; }
    public string? Notes { get; set; }
    public int? GovId { get; set; }
}

// Governament DTOs
public class GovernamentDto
{
    public int Id { get; set; }
    public string GovName { get; set; } = string.Empty;
}

public class CreateGovernamentDto
{
    public string GovName { get; set; } = string.Empty;
}
