using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class ESignRequestDto
{
    public int Id { get; set; }
    public int? FileId { get; set; }
    public string? FileCode { get; set; }
    public string? FilePath { get; set; }
    public string RequestTitle { get; set; } = string.Empty;
    public string? TemplateType { get; set; }
    public string SignerName { get; set; } = string.Empty;
    public string SignerEmail { get; set; } = string.Empty;
    public string? SignerPhoneNumber { get; set; }
    public string? Message { get; set; }
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? ExternalReference { get; set; }
    public string? PublicToken { get; set; }
    public DateTime? TokenExpiresAt { get; set; }
    public string? PublicSignUrl { get; set; }
    public string? SignedByName { get; set; }
    public string RequestedBy { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
    public DateTime? SignedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateESignRequestDto
{
    [Range(1, int.MaxValue)]
    public int? FileId { get; set; }

    [MaxLength(80)]
    public string? TemplateType { get; set; }

    [MaxLength(200)]
    public string? RequestTitle { get; set; }

    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }

    [Required]
    [MaxLength(120)]
    public string SignerName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(256)]
    public string SignerEmail { get; set; } = string.Empty;

    [MaxLength(32)]
    public string? SignerPhoneNumber { get; set; }

    [MaxLength(2000)]
    public string? Message { get; set; }

    public Dictionary<string, string>? Variables { get; set; }
}

public class UpdateESignStatusDto
{
    [Required]
    [MaxLength(24)]
    public string Status { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? ExternalReference { get; set; }
}

public class CreateESignShareLinkDto
{
    [Range(1, 720)]
    public int ExpireAfterHours { get; set; } = 72;
}

public class ESignShareLinkDto
{
    public int RequestId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string PublicSignUrl { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}

public class PublicESignRequestDto
{
    public int Id { get; set; }
    public string RequestTitle { get; set; } = string.Empty;
    public string SignerName { get; set; } = string.Empty;
    public string SignerEmail { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
    public DateTime? TokenExpiresAt { get; set; }
}

public class PublicSignESignRequestDto
{
    [Required]
    [MaxLength(120)]
    public string SignedByName { get; set; } = string.Empty;
}
