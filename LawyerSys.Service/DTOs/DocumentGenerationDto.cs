namespace LawyerSys.DTOs;

public class GenerateDocumentRequestDto
{
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public Dictionary<string, string>? Variables { get; set; }
    public string Format { get; set; } = "txt";
    public string? Culture { get; set; }
    public string? GeneratedContent { get; set; }
    public bool SaveToCase { get; set; } = false;
    public string? DocumentTitle { get; set; }
    public string? DocumentReference { get; set; }
    public string? DocumentCategory { get; set; }
    public string? DocumentNotes { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
}

public class TemplatePreviewRequestDto
{
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public Dictionary<string, string>? Variables { get; set; }
    public string? Culture { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
}

public class FirmBrandingDto
{
    public string? FirmName { get; set; }
    public string? Address { get; set; }
    public string? ContactInfo { get; set; }
    public string? FooterText { get; set; }
    public string? SignatureBlock { get; set; }
}

public class DocumentPartyDto
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string? ContactInfo { get; set; }
}

public class DocumentTemplateDto
{
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class GeneratedDocumentResponseDto
{
    public int? FileId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public byte[]? FileData { get; set; }
    public bool SavedToCase { get; set; }
}

public class DocumentHistoryDto
{
    public int Id { get; set; }
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public int? FileId { get; set; }
    public string Format { get; set; } = string.Empty;
    public string? DocumentTitle { get; set; }
    public string? DocumentReference { get; set; }
    public string? DocumentCategory { get; set; }
    public string GeneratedBy { get; set; } = string.Empty;
    public DateTime GeneratedAt { get; set; }
    public int Version { get; set; }
    public int? ParentDocumentId { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
}

public class DocumentDraftDto
{
    public int Id { get; set; }
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string Format { get; set; } = "docx";
    public string? Scope { get; set; }
    public string? FeeTerms { get; set; }
    public string? Subject { get; set; }
    public string? Statement { get; set; }
    public string? AiInstructions { get; set; }
    public string? PreviewContent { get; set; }
    public string? DocumentTitle { get; set; }
    public string? DocumentReference { get; set; }
    public string? DocumentCategory { get; set; }
    public string? DocumentNotes { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
    public bool SaveToCase { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime LastModifiedAt { get; set; }
    public string? DraftName { get; set; }
}

public class CreateDraftDto
{
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public string Format { get; set; } = "docx";
    public string? Scope { get; set; }
    public string? FeeTerms { get; set; }
    public string? Subject { get; set; }
    public string? Statement { get; set; }
    public string? AiInstructions { get; set; }
    public string? PreviewContent { get; set; }
    public string? DocumentTitle { get; set; }
    public string? DocumentReference { get; set; }
    public string? DocumentCategory { get; set; }
    public string? DocumentNotes { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
    public bool SaveToCase { get; set; }
    public string? DraftName { get; set; }
}

public class UpdateDraftDto : CreateDraftDto
{
}

public class DocumentVersionChainDto
{
    public int RootDocumentId { get; set; }
    public string DocumentTitle { get; set; } = string.Empty;
    public string TemplateType { get; set; } = string.Empty;
    public int TotalVersions { get; set; }
    public List<DocumentVersionDto> Versions { get; set; } = new();
}

public class DocumentVersionDto
{
    public int Id { get; set; }
    public int Version { get; set; }
    public string GeneratedBy { get; set; } = string.Empty;
    public DateTime GeneratedAt { get; set; }
    public string? ChangeSummary { get; set; }
    public int? ParentDocumentId { get; set; }
    public bool IsCurrent { get; set; }
}

public class RegenerateDocumentDto
{
    public string? ChangeSummary { get; set; }
    public string? DocumentTitle { get; set; }
    public string? DocumentReference { get; set; }
    public string? DocumentCategory { get; set; }
    public string? DocumentNotes { get; set; }
    public FirmBrandingDto? Branding { get; set; }
    public List<DocumentPartyDto>? Parties { get; set; }
    public List<string>? ClauseKeys { get; set; }
    public bool SaveToCase { get; set; }
}

public class RestoreVersionResponseDto
{
    public int RestoredDocumentId { get; set; }
    public int NewVersion { get; set; }
    public string Message { get; set; } = string.Empty;
}
