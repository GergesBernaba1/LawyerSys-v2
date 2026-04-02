using System.Text.Json;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using CaseFileEntity = LawyerSys.Data.ScaffoldedModels.Cases_File;
using DocumentDraftEntity = LawyerSys.Data.ScaffoldedModels.DocumentDraft;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;
using GeneratedDocumentEntity = LawyerSys.Data.ScaffoldedModels.GeneratedDocument;

namespace LawyerSys.Services.Documents;

public sealed class DocumentGenerationService : IDocumentGenerationService
{
    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;

    private static readonly Dictionary<string, (string En, string Ar)> ClauseLibrary = new(StringComparer.OrdinalIgnoreCase)
    {
        ["governing-law"] = (
            "Governing Law: This document shall be governed by and construed in accordance with the applicable laws of the jurisdiction.",
            "القانون الحاكم: تخضع هذه الوثيقة وتُفسر وفقًا للقوانين المعمول بها في الولاية القضائية المختصة."
        ),
        ["confidentiality"] = (
            "Confidentiality: The parties agree to keep all non-public information confidential except as required by law.",
            "السرية: يوافق الأطراف على الحفاظ على سرية جميع المعلومات غير العامة إلا إذا تطلب القانون خلاف ذلك."
        ),
        ["dispute-resolution"] = (
            "Dispute Resolution: Any dispute arising from this document shall first be addressed through good-faith negotiation before formal proceedings.",
            "تسوية النزاعات: أي نزاع ينشأ عن هذه الوثيقة يُعالج أولًا عبر التفاوض بحسن نية قبل اللجوء للإجراءات الرسمية."
        ),
        ["severability"] = (
            "Severability: If any provision is held invalid, the remaining provisions shall remain in full force and effect.",
            "قابلية الفصل: إذا اعتبر أي بند غير صالح، تبقى البنود الأخرى نافذة بالكامل."
        ),
        ["force-majeure"] = (
            "Force Majeure: No party shall be liable for delay or failure caused by events beyond reasonable control.",
            "القوة القاهرة: لا يكون أي طرف مسؤولًا عن التأخير أو عدم التنفيذ الناتج عن أحداث خارجة عن السيطرة المعقولة."
        )
    };

    public DocumentGenerationService(LegacyDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    public IEnumerable<DocumentTemplateDto> GetTemplates(string? culture, string? acceptLanguageHeader)
    {
        var effectiveCulture = string.IsNullOrWhiteSpace(culture) ? acceptLanguageHeader : culture;
        return LegalTemplateGenerator.ListTemplates(effectiveCulture)
            .Select(t => new DocumentTemplateDto { Key = t.Key, Name = t.Name, Description = t.Description })
            .ToList();
    }

    public async Task<GenerateDocumentExecutionResult> GenerateAsync(GenerateDocumentRequestDto request, string? userName, string? acceptLanguageHeader, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.TemplateType) || !LegalTemplateGenerator.Exists(request.TemplateType))
        {
            return new GenerateDocumentExecutionResult { IsValidTemplateType = false };
        }

        var culture = string.IsNullOrWhiteSpace(request.Culture) ? acceptLanguageHeader : request.Culture;

        var vars = await BuildVariablesAsync(
            request.CaseCode,
            request.CustomerId,
            request.Variables,
            request.Branding,
            request.Parties,
            request.ClauseKeys,
            culture,
            userName,
            cancellationToken
        );

        var content = string.IsNullOrWhiteSpace(request.GeneratedContent)
            ? LegalTemplateGenerator.Render(request.TemplateType, vars, culture)
            : request.GeneratedContent.Trim();

        content = EnhanceProfessionalSections(content, vars, culture);
        var bytes = LegalTemplateGenerator.BuildOutput(content, request.Format);
        var ext = LegalTemplateGenerator.GetFileExtension(request.Format);
        var contentType = LegalTemplateGenerator.GetContentType(request.Format);
        var fileName = $"{request.TemplateType}-{DateTime.UtcNow:yyyyMMddHHmmss}.{ext}";

        if (request.SaveToCase && request.CaseCode.HasValue)
        {
            var saveResult = await SaveDocumentToCaseAsync(
                request.CaseCode.Value,
                request.CustomerId,
                bytes,
                fileName,
                request.TemplateType,
                request.Format,
                content,
                request.DocumentTitle ?? request.TemplateType,
                request.DocumentReference,
                request.DocumentCategory,
                request.DocumentNotes,
                request.Branding,
                request.Parties,
                request.ClauseKeys,
                ext,
                userName,
                cancellationToken
            );

            return new GenerateDocumentExecutionResult
            {
                IsValidTemplateType = true,
                SavedToCase = true,
                FileId = saveResult.FileId,
                FileName = fileName
            };
        }

        await SaveDocumentHistoryAsync(
            request.TemplateType,
            request.CaseCode,
            request.CustomerId,
            null,
            request.Format,
            content,
            request.DocumentTitle ?? request.TemplateType,
            request.DocumentReference,
            request.DocumentCategory,
            request.DocumentNotes,
            request.Branding,
            request.Parties,
            request.ClauseKeys,
            userName,
            cancellationToken
        );

        return new GenerateDocumentExecutionResult
        {
            IsValidTemplateType = true,
            SavedToCase = false,
            FileName = fileName,
            FileBytes = bytes,
            ContentType = contentType
        };
    }

    public async Task<TemplatePreviewResult> GetTemplatePreviewAsync(TemplatePreviewRequestDto request, string? userName, string? acceptLanguageHeader, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.TemplateType) || !LegalTemplateGenerator.Exists(request.TemplateType))
        {
            return new TemplatePreviewResult { IsValidTemplateType = false };
        }

        var culture = string.IsNullOrWhiteSpace(request.Culture) ? acceptLanguageHeader : request.Culture;

        var vars = await BuildVariablesAsync(
            request.CaseCode,
            request.CustomerId,
            request.Variables,
            request.Branding,
            request.Parties,
            request.ClauseKeys,
            culture,
            userName,
            cancellationToken
        );

        var content = LegalTemplateGenerator.Render(request.TemplateType, vars, culture);
        content = EnhanceProfessionalSections(content, vars, culture);
        return new TemplatePreviewResult { IsValidTemplateType = true, Content = content };
    }

    public IEnumerable<ClauseLibraryItem> GetClauseLibrary(string? culture, string? acceptLanguageHeader)
    {
        var effectiveCulture = string.IsNullOrWhiteSpace(culture) ? acceptLanguageHeader : culture;
        var isArabic = (effectiveCulture ?? string.Empty).StartsWith("ar", StringComparison.OrdinalIgnoreCase);

        return ClauseLibrary
            .Select(c => new ClauseLibraryItem
            {
                Key = c.Key,
                Text = isArabic ? c.Value.Ar : c.Value.En
            })
            .ToList();
    }

    public async Task<IEnumerable<DocumentHistoryDto>> GetHistoryAsync(int? caseCode, int? limit, CancellationToken cancellationToken = default)
    {
        var query = _context.GeneratedDocuments.Where(d => !d.IsDeleted).AsQueryable();

        if (caseCode.HasValue)
        {
            query = query.Where(d => d.CaseCode == caseCode.Value);
        }

        var docs = await query
            .OrderByDescending(d => d.GeneratedAt)
            .Take(limit ?? 50)
            .ToListAsync(cancellationToken);

        return docs.Select(MapHistory).ToList();
    }

    public async Task<DocumentHistoryDto?> GetHistoryByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);

        return doc == null ? null : MapHistory(doc);
    }

    public async Task<DocumentHistoryContentResult?> GetHistoryContentAsync(int id, CancellationToken cancellationToken = default)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);

        if (doc == null)
        {
            return null;
        }

        return new DocumentHistoryContentResult
        {
            Content = doc.GeneratedContent,
            Branding = DeserializeJson<FirmBrandingDto>(doc.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(doc.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(doc.ClauseKeysJson)
        };
    }

    public async Task<IEnumerable<DocumentDraftDto>> GetDraftsAsync(string userName, CancellationToken cancellationToken = default)
    {
        var drafts = await _context.DocumentDrafts
            .Where(d => !d.IsDeleted && d.CreatedBy == userName)
            .OrderByDescending(d => d.LastModifiedAt)
            .ToListAsync(cancellationToken);

        return drafts.Select(MapDraft).ToList();
    }
    public async Task<DocumentDraftDto?> GetDraftByIdAsync(int id, string userName, CancellationToken cancellationToken = default)
    {
        var draft = await _context.DocumentDrafts
            .Where(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName)
            .FirstOrDefaultAsync(cancellationToken);

        return draft == null ? null : MapDraft(draft);
    }

    public async Task<DocumentDraftDto> CreateDraftAsync(CreateDraftDto dto, string userName, CancellationToken cancellationToken = default)
    {
        var now = NormalizeLegacyTimestamp(DateTime.UtcNow);

        var draft = new DocumentDraftEntity
        {
            TemplateType = dto.TemplateType,
            CaseCode = dto.CaseCode,
            CustomerId = dto.CustomerId,
            Format = dto.Format,
            Scope = dto.Scope,
            FeeTerms = dto.FeeTerms,
            Subject = dto.Subject,
            Statement = dto.Statement,
            AiInstructions = dto.AiInstructions,
            PreviewContent = dto.PreviewContent,
            DocumentTitle = dto.DocumentTitle,
            DocumentReference = dto.DocumentReference,
            DocumentCategory = dto.DocumentCategory,
            DocumentNotes = dto.DocumentNotes,
            BrandingJson = SerializeJsonOrNull(dto.Branding),
            PartiesJson = SerializeJsonOrNull(dto.Parties),
            ClauseKeysJson = SerializeJsonOrNull(dto.ClauseKeys),
            SaveToCase = dto.SaveToCase,
            DraftName = dto.DraftName ?? $"Draft - {DateTime.UtcNow:yyyy-MM-dd HH:mm}",
            CreatedBy = userName,
            CreatedAt = now,
            LastModifiedAt = now
        };

        _context.DocumentDrafts.Add(draft);
        await _context.SaveChangesAsync(cancellationToken);

        return MapDraft(draft);
    }

    public async Task<bool> UpdateDraftAsync(int id, UpdateDraftDto dto, string userName, CancellationToken cancellationToken = default)
    {
        var draft = await _context.DocumentDrafts
            .FirstOrDefaultAsync(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName, cancellationToken);

        if (draft == null)
        {
            return false;
        }

        draft.TemplateType = dto.TemplateType;
        draft.CaseCode = dto.CaseCode;
        draft.CustomerId = dto.CustomerId;
        draft.Format = dto.Format;
        draft.Scope = dto.Scope;
        draft.FeeTerms = dto.FeeTerms;
        draft.Subject = dto.Subject;
        draft.Statement = dto.Statement;
        draft.AiInstructions = dto.AiInstructions;
        draft.PreviewContent = dto.PreviewContent;
        draft.DocumentTitle = dto.DocumentTitle;
        draft.DocumentReference = dto.DocumentReference;
        draft.DocumentCategory = dto.DocumentCategory;
        draft.DocumentNotes = dto.DocumentNotes;
        draft.BrandingJson = SerializeJsonOrNull(dto.Branding);
        draft.PartiesJson = SerializeJsonOrNull(dto.Parties);
        draft.ClauseKeysJson = SerializeJsonOrNull(dto.ClauseKeys);
        draft.SaveToCase = dto.SaveToCase;
        draft.DraftName = dto.DraftName;
        draft.LastModifiedAt = NormalizeLegacyTimestamp(DateTime.UtcNow);

        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteDraftAsync(int id, string userName, CancellationToken cancellationToken = default)
    {
        var draft = await _context.DocumentDrafts
            .FirstOrDefaultAsync(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName, cancellationToken);

        if (draft == null)
        {
            return false;
        }

        draft.IsDeleted = true;
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<DocumentVersionChainDto?> GetVersionChainAsync(int id, CancellationToken cancellationToken = default)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);

        if (doc == null)
        {
            return null;
        }

        var rootId = doc.ParentDocumentId ?? doc.Id;

        var allVersions = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .OrderBy(d => d.Version)
            .ToListAsync(cancellationToken);

        var latestVersion = allVersions.MaxBy(v => v.Version);
        var latestId = latestVersion?.Id ?? rootId;

        return new DocumentVersionChainDto
        {
            RootDocumentId = rootId,
            DocumentTitle = doc.DocumentTitle ?? doc.TemplateType,
            TemplateType = doc.TemplateType,
            TotalVersions = allVersions.Count,
            Versions = allVersions.Select(v => new DocumentVersionDto
            {
                Id = v.Id,
                Version = v.Version,
                GeneratedBy = v.GeneratedBy,
                GeneratedAt = v.GeneratedAt,
                ParentDocumentId = v.ParentDocumentId,
                IsCurrent = v.Id == latestId
            }).ToList()
        };
    }

    public async Task<GeneratedDocumentResponseDto?> RegenerateAsNewVersionAsync(int id, RegenerateDocumentDto? dto, string? userName, CancellationToken cancellationToken = default)
    {
        var originalDoc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);

        if (originalDoc == null)
        {
            return null;
        }

        var rootId = originalDoc.ParentDocumentId ?? originalDoc.Id;
        var maxVersion = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .MaxAsync(d => d.Version, cancellationToken);

        var newContent = originalDoc.GeneratedContent ?? string.Empty;
        var branding = dto?.Branding ?? DeserializeJson<FirmBrandingDto>(originalDoc.BrandingJson);
        var parties = dto?.Parties ?? DeserializeJson<List<DocumentPartyDto>>(originalDoc.PartiesJson);
        var clauseKeys = dto?.ClauseKeys ?? DeserializeJson<List<string>>(originalDoc.ClauseKeysJson);

        var bytes = LegalTemplateGenerator.BuildOutput(newContent, originalDoc.Format);
        var ext = LegalTemplateGenerator.GetFileExtension(originalDoc.Format);
        var fileName = $"{originalDoc.TemplateType}-v{maxVersion + 1}-{DateTime.UtcNow:yyyyMMddHHmmss}.{ext}";

        int? fileId = null;

        if (dto?.SaveToCase == true && originalDoc.CaseCode.HasValue)
        {
            var saveResult = await SaveDocumentToCaseAsync(
                originalDoc.CaseCode.Value,
                originalDoc.CustomerId,
                bytes,
                fileName,
                originalDoc.TemplateType,
                originalDoc.Format,
                newContent,
                dto?.DocumentTitle ?? originalDoc.DocumentTitle ?? originalDoc.TemplateType,
                dto?.DocumentReference ?? originalDoc.DocumentReference,
                dto?.DocumentCategory ?? originalDoc.DocumentCategory,
                dto?.DocumentNotes ?? originalDoc.DocumentNotes,
                branding,
                parties,
                clauseKeys,
                ext,
                userName,
                cancellationToken
            );

            fileId = saveResult.FileId;
        }

        var newVersionDoc = new GeneratedDocumentEntity
        {
            TemplateType = originalDoc.TemplateType,
            CaseCode = originalDoc.CaseCode,
            CustomerId = originalDoc.CustomerId,
            FileId = fileId,
            Format = originalDoc.Format,
            DocumentTitle = dto?.DocumentTitle ?? originalDoc.DocumentTitle,
            DocumentReference = dto?.DocumentReference ?? originalDoc.DocumentReference,
            DocumentCategory = dto?.DocumentCategory ?? originalDoc.DocumentCategory,
            DocumentNotes = dto?.DocumentNotes ?? originalDoc.DocumentNotes,
            BrandingJson = SerializeJsonOrNull(branding),
            PartiesJson = SerializeJsonOrNull(parties),
            ClauseKeysJson = SerializeJsonOrNull(clauseKeys),
            GeneratedContent = newContent,
            GeneratedBy = userName ?? "System",
            GeneratedAt = NormalizeLegacyTimestamp(DateTime.UtcNow),
            Version = maxVersion + 1,
            ParentDocumentId = rootId
        };

        _context.GeneratedDocuments.Add(newVersionDoc);
        await _context.SaveChangesAsync(cancellationToken);

        return new GeneratedDocumentResponseDto
        {
            FileId = fileId,
            FileName = fileName,
            SavedToCase = dto?.SaveToCase ?? false
        };
    }

    public async Task<RestoreVersionResponseDto?> RestoreVersionAsync(int id, string? userName, CancellationToken cancellationToken = default)
    {
        var docToRestore = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);

        if (docToRestore == null)
        {
            return null;
        }

        var rootId = docToRestore.ParentDocumentId ?? docToRestore.Id;
        var maxVersion = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .MaxAsync(d => d.Version, cancellationToken);

        var restoredDoc = new GeneratedDocumentEntity
        {
            TemplateType = docToRestore.TemplateType,
            CaseCode = docToRestore.CaseCode,
            CustomerId = docToRestore.CustomerId,
            FileId = docToRestore.FileId,
            Format = docToRestore.Format,
            DocumentTitle = docToRestore.DocumentTitle,
            DocumentReference = docToRestore.DocumentReference,
            DocumentCategory = docToRestore.DocumentCategory,
            DocumentNotes = docToRestore.DocumentNotes,
            BrandingJson = docToRestore.BrandingJson,
            PartiesJson = docToRestore.PartiesJson,
            ClauseKeysJson = docToRestore.ClauseKeysJson,
            GeneratedContent = docToRestore.GeneratedContent,
            GeneratedBy = userName ?? "System",
            GeneratedAt = NormalizeLegacyTimestamp(DateTime.UtcNow),
            Version = maxVersion + 1,
            ParentDocumentId = rootId
        };

        _context.GeneratedDocuments.Add(restoredDoc);
        await _context.SaveChangesAsync(cancellationToken);

        return new RestoreVersionResponseDto
        {
            RestoredDocumentId = restoredDoc.Id,
            NewVersion = restoredDoc.Version,
            Message = $"Document restored as version {restoredDoc.Version}"
        };
    }

    private async Task<Dictionary<string, string>> BuildVariablesAsync(
        int? caseCode,
        int? customerId,
        Dictionary<string, string>? requestVariables,
        FirmBrandingDto? branding,
        List<DocumentPartyDto>? parties,
        List<string>? clauseKeys,
        string? culture,
        string? userName,
        CancellationToken cancellationToken)
    {
        var vars = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Today"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            ["LawyerName"] = userName ?? "Lawyer",
            ["LawFirmName"] = "LawyerSys Office",
            ["Scope"] = "Provide legal representation and consultation services.",
            ["FeeTerms"] = "As agreed between parties.",
            ["Subject"] = "Case filing statement",
            ["Statement"] = "Detailed legal statement will be inserted here.",
            ["CourtName"] = "N/A",
            ["CaseCode"] = caseCode?.ToString() ?? "N/A",
            ["CaseType"] = "N/A",
            ["CustomerName"] = "N/A"
        };

        if (caseCode.HasValue)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode.Value, cancellationToken);
            if (caseEntity != null)
            {
                vars["CaseCode"] = caseEntity.Code.ToString();
                vars["CaseType"] = caseEntity.Invition_Type;

                var courtName = await _context.Cases_Courts
                    .Where(cc => cc.Case_Code == caseEntity.Code)
                    .Select(cc => cc.Court.Name)
                    .FirstOrDefaultAsync(cancellationToken);

                if (!string.IsNullOrWhiteSpace(courtName))
                {
                    vars["CourtName"] = courtName;
                }
            }
        }

        if (!customerId.HasValue && caseCode.HasValue)
        {
            customerId = await _context.Custmors_Cases
                .Where(cc => cc.Case_Id == caseCode.Value)
                .Select(cc => (int?)cc.Custmors_Id)
                .FirstOrDefaultAsync(cancellationToken);
        }

        if (customerId.HasValue)
        {
            var customerName = await _context.Customers
                .Where(c => c.Id == customerId.Value)
                .Select(c => c.Users.Full_Name)
                .FirstOrDefaultAsync(cancellationToken);

            if (!string.IsNullOrWhiteSpace(customerName))
            {
                vars["CustomerName"] = customerName;
            }
        }

        if (requestVariables != null)
        {
            foreach (var kv in requestVariables)
            {
                vars[kv.Key] = kv.Value;
            }
        }

        if (branding != null)
        {
            if (!string.IsNullOrWhiteSpace(branding.FirmName))
            {
                vars["LawFirmName"] = branding.FirmName.Trim();
            }

            vars["FirmAddress"] = branding.Address?.Trim() ?? string.Empty;
            vars["FirmContactInfo"] = branding.ContactInfo?.Trim() ?? string.Empty;
            vars["FirmFooter"] = branding.FooterText?.Trim() ?? string.Empty;
            vars["SignatureBlock"] = branding.SignatureBlock?.Trim() ?? string.Empty;
        }

        if (parties != null && parties.Count > 0)
        {
            var partyLines = parties
                .Where(p => !string.IsNullOrWhiteSpace(p.Name))
                .Select((p, idx) =>
                {
                    var role = string.IsNullOrWhiteSpace(p.Role) ? "Party" : p.Role.Trim();
                    var contact = string.IsNullOrWhiteSpace(p.ContactInfo) ? string.Empty : $" - {p.ContactInfo.Trim()}";
                    return $"{idx + 1}. {role}: {p.Name.Trim()}{contact}";
                })
                .ToList();

            vars["PartyList"] = string.Join('\n', partyLines);
        }
        else
        {
            vars["PartyList"] = string.Empty;
        }

        var clauseText = BuildClauseText(clauseKeys, culture);
        vars["AdditionalClauses"] = string.IsNullOrWhiteSpace(clauseText) ? string.Empty : clauseText;

        return vars;
    }

    private async Task<(int FileId, int HistoryId)> SaveDocumentToCaseAsync(
        int caseCode,
        int? customerId,
        byte[] fileData,
        string fileName,
        string templateType,
        string format,
        string content,
        string documentTitle,
        string? documentReference,
        string? documentCategory,
        string? documentNotes,
        FirmBrandingDto? branding,
        List<DocumentPartyDto>? parties,
        List<string>? clauseKeys,
        string fileExtension,
        string? userName,
        CancellationToken cancellationToken)
    {
        var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
        if (!Directory.Exists(uploadsPath))
        {
            Directory.CreateDirectory(uploadsPath);
        }

        var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
        var filePath = Path.Combine(uploadsPath, uniqueFileName);
        await System.IO.File.WriteAllBytesAsync(filePath, fileData, cancellationToken);

        var isDocument = new[] { ".pdf", ".doc", ".docx" }.Contains(fileExtension.ToLowerInvariant());
        var fileEntity = new FileEntity
        {
            Path = $"/Uploads/{uniqueFileName}",
            Code = documentTitle,
            type = isDocument
        };

        _context.Files.Add(fileEntity);
        await _context.SaveChangesAsync(cancellationToken);

        var caseFile = new CaseFileEntity
        {
            Case_Id = caseCode,
            File_Id = fileEntity.Id
        };

        _context.Cases_Files.Add(caseFile);
        await _context.SaveChangesAsync(cancellationToken);

        var historyId = await SaveDocumentHistoryAsync(
            templateType,
            caseCode,
            customerId,
            fileEntity.Id,
            format,
            content,
            documentTitle,
            documentReference,
            documentCategory,
            documentNotes,
            branding,
            parties,
            clauseKeys,
            userName,
            cancellationToken
        );

        return (fileEntity.Id, historyId);
    }

    private async Task<int> SaveDocumentHistoryAsync(
        string templateType,
        int? caseCode,
        int? customerId,
        int? fileId,
        string format,
        string content,
        string documentTitle,
        string? documentReference,
        string? documentCategory,
        string? documentNotes,
        FirmBrandingDto? branding,
        List<DocumentPartyDto>? parties,
        List<string>? clauseKeys,
        string? userName,
        CancellationToken cancellationToken)
    {
        var history = new GeneratedDocumentEntity
        {
            TemplateType = templateType,
            CaseCode = caseCode,
            CustomerId = customerId,
            FileId = fileId,
            Format = format,
            DocumentTitle = documentTitle,
            DocumentReference = documentReference,
            DocumentCategory = documentCategory,
            DocumentNotes = documentNotes,
            BrandingJson = SerializeJsonOrNull(branding),
            PartiesJson = SerializeJsonOrNull(parties),
            ClauseKeysJson = SerializeJsonOrNull(clauseKeys),
            GeneratedContent = content,
            GeneratedBy = userName ?? "System",
            GeneratedAt = NormalizeLegacyTimestamp(DateTime.UtcNow),
            Version = 1
        };

        _context.GeneratedDocuments.Add(history);
        await _context.SaveChangesAsync(cancellationToken);

        return history.Id;
    }

    private static string BuildClauseText(IEnumerable<string>? clauseKeys, string? culture)
    {
        if (clauseKeys == null)
        {
            return string.Empty;
        }

        var isArabic = (culture ?? string.Empty).StartsWith("ar", StringComparison.OrdinalIgnoreCase);
        var clauses = clauseKeys
            .Where(k => !string.IsNullOrWhiteSpace(k))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Where(k => ClauseLibrary.ContainsKey(k))
            .Select(k => isArabic ? ClauseLibrary[k].Ar : ClauseLibrary[k].En)
            .ToList();

        return clauses.Count == 0 ? string.Empty : string.Join("\n\n", clauses);
    }

    private static string EnhanceProfessionalSections(string content, IDictionary<string, string> vars, string? culture)
    {
        var result = content?.Trim() ?? string.Empty;
        var isArabic = (culture ?? string.Empty).StartsWith("ar", StringComparison.OrdinalIgnoreCase);

        if (vars.TryGetValue("PartyList", out var partyList) && !string.IsNullOrWhiteSpace(partyList) &&
            !result.Contains(partyList, StringComparison.Ordinal))
        {
            var sectionTitle = isArabic ? "الأطراف" : "PARTIES";
            result = $"{result}\n\n{sectionTitle}\n{partyList}";
        }

        if (vars.TryGetValue("AdditionalClauses", out var clauses) && !string.IsNullOrWhiteSpace(clauses) &&
            !result.Contains(clauses, StringComparison.Ordinal))
        {
            var sectionTitle = isArabic ? "بنود إضافية" : "ADDITIONAL CLAUSES";
            result = $"{result}\n\n{sectionTitle}\n{clauses}";
        }

        return result;
    }

    private static DateTime NormalizeLegacyTimestamp(DateTime value)
    {
        return value.Kind == DateTimeKind.Utc
            ? DateTime.SpecifyKind(value, DateTimeKind.Unspecified)
            : value;
    }

    private static string? SerializeJsonOrNull<T>(T? value)
    {
        if (value == null)
        {
            return null;
        }

        return JsonSerializer.Serialize(value);
    }

    private static T? DeserializeJson<T>(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return default;
        }

        try
        {
            return JsonSerializer.Deserialize<T>(json);
        }
        catch
        {
            return default;
        }
    }

    private static DocumentHistoryDto MapHistory(GeneratedDocumentEntity d)
    {
        return new DocumentHistoryDto
        {
            Id = d.Id,
            TemplateType = d.TemplateType,
            CaseCode = d.CaseCode,
            CustomerId = d.CustomerId,
            FileId = d.FileId,
            Format = d.Format,
            DocumentTitle = d.DocumentTitle,
            DocumentReference = d.DocumentReference,
            DocumentCategory = d.DocumentCategory,
            GeneratedBy = d.GeneratedBy,
            GeneratedAt = d.GeneratedAt,
            Version = d.Version,
            ParentDocumentId = d.ParentDocumentId,
            Branding = DeserializeJson<FirmBrandingDto>(d.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(d.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(d.ClauseKeysJson)
        };
    }

    private static DocumentDraftDto MapDraft(DocumentDraftEntity d)
    {
        return new DocumentDraftDto
        {
            Id = d.Id,
            TemplateType = d.TemplateType,
            CaseCode = d.CaseCode,
            CustomerId = d.CustomerId,
            Format = d.Format,
            Scope = d.Scope,
            FeeTerms = d.FeeTerms,
            Subject = d.Subject,
            Statement = d.Statement,
            AiInstructions = d.AiInstructions,
            PreviewContent = d.PreviewContent,
            DocumentTitle = d.DocumentTitle,
            DocumentReference = d.DocumentReference,
            DocumentCategory = d.DocumentCategory,
            DocumentNotes = d.DocumentNotes,
            Branding = DeserializeJson<FirmBrandingDto>(d.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(d.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(d.ClauseKeysJson),
            SaveToCase = d.SaveToCase,
            CreatedBy = d.CreatedBy,
            CreatedAt = d.CreatedAt,
            LastModifiedAt = d.LastModifiedAt,
            DraftName = d.DraftName
        };
    }
}
