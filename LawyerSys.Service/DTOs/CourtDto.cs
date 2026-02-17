using System.ComponentModel.DataAnnotations;

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
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(400)]
    public string Address { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string Telephone { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
    public int GovId { get; set; }
}

public class UpdateCourtDto
{
    [MaxLength(200)]
    public string? Name { get; set; }

    [MaxLength(400)]
    public string? Address { get; set; }

    [MaxLength(50)]
    public string? Telephone { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
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
    [Required]
    [MaxLength(150)]
    public string GovName { get; set; } = string.Empty;
}
