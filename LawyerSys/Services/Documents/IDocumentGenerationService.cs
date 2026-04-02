using LawyerSys.DTOs;

namespace LawyerSys.Services.Documents;

public interface IDocumentGenerationService
{
    IEnumerable<DocumentTemplateDto> GetTemplates(string? culture, string? acceptLanguageHeader);
    Task<GenerateDocumentExecutionResult> GenerateAsync(GenerateDocumentRequestDto request, string? userName, string? acceptLanguageHeader, CancellationToken cancellationToken = default);
    Task<TemplatePreviewResult> GetTemplatePreviewAsync(TemplatePreviewRequestDto request, string? userName, string? acceptLanguageHeader, CancellationToken cancellationToken = default);
    IEnumerable<ClauseLibraryItem> GetClauseLibrary(string? culture, string? acceptLanguageHeader);

    Task<IEnumerable<DocumentHistoryDto>> GetHistoryAsync(int? caseCode, int? limit, CancellationToken cancellationToken = default);
    Task<DocumentHistoryDto?> GetHistoryByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<DocumentHistoryContentResult?> GetHistoryContentAsync(int id, CancellationToken cancellationToken = default);

    Task<IEnumerable<DocumentDraftDto>> GetDraftsAsync(string userName, CancellationToken cancellationToken = default);
    Task<DocumentDraftDto?> GetDraftByIdAsync(int id, string userName, CancellationToken cancellationToken = default);
    Task<DocumentDraftDto> CreateDraftAsync(CreateDraftDto dto, string userName, CancellationToken cancellationToken = default);
    Task<bool> UpdateDraftAsync(int id, UpdateDraftDto dto, string userName, CancellationToken cancellationToken = default);
    Task<bool> DeleteDraftAsync(int id, string userName, CancellationToken cancellationToken = default);

    Task<DocumentVersionChainDto?> GetVersionChainAsync(int id, CancellationToken cancellationToken = default);
    Task<GeneratedDocumentResponseDto?> RegenerateAsNewVersionAsync(int id, RegenerateDocumentDto? dto, string? userName, CancellationToken cancellationToken = default);
    Task<RestoreVersionResponseDto?> RestoreVersionAsync(int id, string? userName, CancellationToken cancellationToken = default);
}

public sealed class GenerateDocumentExecutionResult
{
    public bool IsValidTemplateType { get; init; } = true;
    public bool SavedToCase { get; init; }
    public int? FileId { get; init; }
    public string FileName { get; init; } = string.Empty;
    public byte[]? FileBytes { get; init; }
    public string? ContentType { get; init; }
}

public sealed class TemplatePreviewResult
{
    public bool IsValidTemplateType { get; init; } = true;
    public string Content { get; init; } = string.Empty;
}

public sealed class ClauseLibraryItem
{
    public string Key { get; init; } = string.Empty;
    public string Text { get; init; } = string.Empty;
}

public sealed class DocumentHistoryContentResult
{
    public string? Content { get; init; }
    public FirmBrandingDto? Branding { get; init; }
    public List<DocumentPartyDto>? Parties { get; init; }
    public List<string>? ClauseKeys { get; init; }
}
