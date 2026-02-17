using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

// Judicial Document DTOs
public class JudicialDocumentDto
{
    public int Id { get; set; }
    public string DocType { get; set; } = string.Empty;
    public int DocNum { get; set; }
    public string DocDetails { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
    public int NumOfAgent { get; set; }
    public int CustomerId { get; set; }
    public string? CustomerName { get; set; }
}

public class CreateJudicialDocumentDto
{
    [Required]
    [MaxLength(100)]
    public string DocType { get; set; } = string.Empty;

    [Range(1, int.MaxValue)]
    public int DocNum { get; set; }

    [Required]
    [MaxLength(4000)]
    public string DocDetails { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(0, int.MaxValue)]
    public int NumOfAgent { get; set; }

    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }
}

public class UpdateJudicialDocumentDto
{
    [MaxLength(100)]
    public string? DocType { get; set; }

    [Range(1, int.MaxValue)]
    public int? DocNum { get; set; }

    [MaxLength(4000)]
    public string? DocDetails { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(0, int.MaxValue)]
    public int? NumOfAgent { get; set; }
}
