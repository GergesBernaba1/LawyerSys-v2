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
    public string DocType { get; set; } = string.Empty;
    public int DocNum { get; set; }
    public string DocDetails { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public int NumOfAgent { get; set; }
    public int CustomerId { get; set; }
}

public class UpdateJudicialDocumentDto
{
    public string? DocType { get; set; }
    public int? DocNum { get; set; }
    public string? DocDetails { get; set; }
    public string? Notes { get; set; }
    public int? NumOfAgent { get; set; }
}
