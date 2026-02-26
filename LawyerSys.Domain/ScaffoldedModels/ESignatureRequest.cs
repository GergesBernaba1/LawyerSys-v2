namespace LawyerSys.Data.ScaffoldedModels;

public partial class ESignatureRequest
{
    public int Id { get; set; }
    public int? FileId { get; set; }
    public string RequestTitle { get; set; } = string.Empty;
    public string? TemplateType { get; set; }
    public string SignerName { get; set; } = string.Empty;
    public string SignerEmail { get; set; } = string.Empty;
    public string? SignerPhoneNumber { get; set; }
    public string? Message { get; set; }
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string Status { get; set; } = "Pending";
    public string? ExternalReference { get; set; }
    public string? PublicToken { get; set; }
    public DateTime? TokenExpiresAt { get; set; }
    public string? SignedByName { get; set; }
    public string RequestedBy { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
    public DateTime? SignedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
