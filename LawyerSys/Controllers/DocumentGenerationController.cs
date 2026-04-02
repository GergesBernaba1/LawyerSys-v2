using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Services.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;
using CaseFileEntity = LawyerSys.Data.ScaffoldedModels.Cases_File;
using GeneratedDocumentEntity = LawyerSys.Data.ScaffoldedModels.GeneratedDocument;
using DocumentDraftEntity = LawyerSys.Data.ScaffoldedModels.DocumentDraft;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class DocumentGenerationController : ControllerBase
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

    public DocumentGenerationController(LegacyDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpGet("templates")]
    public ActionResult<IEnumerable<DocumentTemplateDto>> GetTemplates([FromQuery] string? culture = null)
    {
        // Try to get culture from Accept-Language header if not provided as query param
        if (string.IsNullOrEmpty(culture))
        {
            culture = Request.Headers.AcceptLanguage.FirstOrDefault();
        }
        
        var templates = LegalTemplateGenerator.ListTemplates(culture)
            .Select(t => new DocumentTemplateDto { Key = t.Key, Name = t.Name, Description = t.Description })
            .ToList();

        return Ok(templates);
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateDocumentRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.TemplateType) || !LegalTemplateGenerator.Exists(request.TemplateType))
        {
            return BadRequest(new { message = "Invalid template type" });
        }

        var culture = request.Culture;
        if (string.IsNullOrWhiteSpace(culture))
        {
            culture = Request.Headers.AcceptLanguage.FirstOrDefault();
        }

        var vars = await BuildVariablesAsync(
            request.CaseCode,
            request.CustomerId,
            request.Variables,
            request.Branding,
            request.Parties,
            request.ClauseKeys,
            culture
        );

        var content = string.IsNullOrWhiteSpace(request.GeneratedContent)
            ? LegalTemplateGenerator.Render(request.TemplateType, vars, culture)
            : request.GeneratedContent.Trim();
        content = EnhanceProfessionalSections(content, vars, culture);
        var bytes = LegalTemplateGenerator.BuildOutput(content, request.Format);
        var ext = LegalTemplateGenerator.GetFileExtension(request.Format);
        var contentType = LegalTemplateGenerator.GetContentType(request.Format);
        var fileName = $"{request.TemplateType}-{DateTime.UtcNow:yyyyMMddHHmmss}.{ext}";

        // If SaveToCase is requested and we have a case code, save to the database
        if (request.SaveToCase && request.CaseCode.HasValue)
        {
            var result = await SaveDocumentToCaseAsync(
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
                ext
            );

            return Ok(new GeneratedDocumentResponseDto
            {
                FileId = result.FileId,
                FileName = fileName,
                SavedToCase = true
            });
        }

        // Save to history even if not saving to case
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
            request.ClauseKeys
        );

        // Otherwise, return as file download
        return File(bytes, contentType, fileName);
    }

    [HttpPost("template-preview")]
    public async Task<ActionResult<object>> GetTemplatePreview([FromBody] TemplatePreviewRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.TemplateType) || !LegalTemplateGenerator.Exists(request.TemplateType))
        {
            return BadRequest(new { message = "Invalid template type" });
        }

        var culture = request.Culture;
        if (string.IsNullOrWhiteSpace(culture))
        {
            culture = Request.Headers.AcceptLanguage.FirstOrDefault();
        }

        var vars = await BuildVariablesAsync(
            request.CaseCode,
            request.CustomerId,
            request.Variables,
            request.Branding,
            request.Parties,
            request.ClauseKeys,
            culture
        );

        var content = LegalTemplateGenerator.Render(request.TemplateType, vars, culture);
        content = EnhanceProfessionalSections(content, vars, culture);
        return Ok(new { content });
    }

    [HttpGet("clauses")]
    public ActionResult<object> GetClauseLibrary([FromQuery] string? culture = null)
    {
        if (string.IsNullOrWhiteSpace(culture))
        {
            culture = Request.Headers.AcceptLanguage.FirstOrDefault();
        }

        var isArabic = (culture ?? string.Empty).StartsWith("ar", StringComparison.OrdinalIgnoreCase);
        var items = ClauseLibrary
            .Select(c => new
            {
                key = c.Key,
                text = isArabic ? c.Value.Ar : c.Value.En
            })
            .ToList();

        return Ok(items);
    }

    private async Task<Dictionary<string, string>> BuildVariablesAsync(
        int? caseCode,
        int? customerId,
        Dictionary<string, string>? requestVariables,
        FirmBrandingDto? branding,
        List<DocumentPartyDto>? parties,
        List<string>? clauseKeys,
        string? culture)
    {
        var vars = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Today"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            ["LawyerName"] = User.Identity?.Name ?? "Lawyer",
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
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode.Value);
            if (caseEntity != null)
            {
                vars["CaseCode"] = caseEntity.Code.ToString();
                vars["CaseType"] = caseEntity.Invition_Type;

                var courtName = await _context.Cases_Courts
                    .Where(cc => cc.Case_Code == caseEntity.Code)
                    .Select(cc => cc.Court.Name)
                    .FirstOrDefaultAsync();

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
                .FirstOrDefaultAsync();
        }

        if (customerId.HasValue)
        {
            var customerName = await _context.Customers
                .Where(c => c.Id == customerId.Value)
                .Select(c => c.Users.Full_Name)
                .FirstOrDefaultAsync();

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
        if (!string.IsNullOrWhiteSpace(clauseText))
        {
            vars["AdditionalClauses"] = clauseText;
        }
        else
        {
            vars["AdditionalClauses"] = string.Empty;
        }

        return vars;
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
        string fileExtension)
    {
        // Save file to disk
        var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
        if (!Directory.Exists(uploadsPath))
        {
            Directory.CreateDirectory(uploadsPath);
        }

        var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
        var filePath = Path.Combine(uploadsPath, uniqueFileName);
        await System.IO.File.WriteAllBytesAsync(filePath, fileData);

        // Create file entity
        var isDocument = new[] { ".pdf", ".doc", ".docx" }.Contains(fileExtension.ToLowerInvariant());
        var fileEntity = new FileEntity
        {
            Path = $"/Uploads/{uniqueFileName}",
            Code = documentTitle,
            type = isDocument
        };

        _context.Files.Add(fileEntity);
        await _context.SaveChangesAsync();

        // Link file to case
        var caseFile = new CaseFileEntity
        {
            Case_Id = caseCode,
            File_Id = fileEntity.Id
        };

        _context.Cases_Files.Add(caseFile);
        await _context.SaveChangesAsync();

        // Save to history
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
            clauseKeys
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
        List<string>? clauseKeys)
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
            GeneratedBy = User.Identity?.Name ?? "System",
            GeneratedAt = DateTime.UtcNow,
            Version = 1
        };

        _context.GeneratedDocuments.Add(history);
        await _context.SaveChangesAsync();

        return history.Id;
    }

    // ===== HISTORY ENDPOINTS =====

    [HttpGet("history")]
    public async Task<ActionResult<IEnumerable<DocumentHistoryDto>>> GetHistory(
        [FromQuery] int? caseCode = null,
        [FromQuery] int? limit = 50)
    {
        var query = _context.GeneratedDocuments
            .Where(d => !d.IsDeleted)
            .AsQueryable();

        if (caseCode.HasValue)
        {
            query = query.Where(d => d.CaseCode == caseCode.Value);
        }

        var history = await query
            .OrderByDescending(d => d.GeneratedAt)
            .Take(limit ?? 50)
            .Select(d => new
            {
                d.Id,
                d.TemplateType,
                d.CaseCode,
                d.CustomerId,
                d.FileId,
                d.Format,
                d.DocumentTitle,
                d.DocumentReference,
                d.DocumentCategory,
                d.GeneratedBy,
                d.GeneratedAt,
                d.Version,
                d.ParentDocumentId,
                d.BrandingJson,
                d.PartiesJson,
                d.ClauseKeysJson
            })
            .ToListAsync();

        return Ok(history.Select(d => new DocumentHistoryDto
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
        }));
    }

    [HttpGet("history/{id}")]
    public async Task<ActionResult<DocumentHistoryDto>> GetHistoryById(int id)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .Select(d => new
            {
                d.Id,
                d.TemplateType,
                d.CaseCode,
                d.CustomerId,
                d.FileId,
                d.Format,
                d.DocumentTitle,
                d.DocumentReference,
                d.DocumentCategory,
                d.GeneratedBy,
                d.GeneratedAt,
                d.Version,
                d.ParentDocumentId,
                d.BrandingJson,
                d.PartiesJson,
                d.ClauseKeysJson
            })
            .FirstOrDefaultAsync();

        if (doc == null)
        {
            return NotFound(new { message = "Document history not found" });
        }

        return Ok(new DocumentHistoryDto
        {
            Id = doc.Id,
            TemplateType = doc.TemplateType,
            CaseCode = doc.CaseCode,
            CustomerId = doc.CustomerId,
            FileId = doc.FileId,
            Format = doc.Format,
            DocumentTitle = doc.DocumentTitle,
            DocumentReference = doc.DocumentReference,
            DocumentCategory = doc.DocumentCategory,
            GeneratedBy = doc.GeneratedBy,
            GeneratedAt = doc.GeneratedAt,
            Version = doc.Version,
            ParentDocumentId = doc.ParentDocumentId,
            Branding = DeserializeJson<FirmBrandingDto>(doc.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(doc.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(doc.ClauseKeysJson)
        });
    }

    [HttpGet("history/{id}/content")]
    public async Task<ActionResult<string>> GetHistoryContent( int id)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync();

        if (doc == null)
        {
            return NotFound(new { message = "Document history not found" });
        }

        return Ok(new
        {
            content = doc.GeneratedContent,
            branding = DeserializeJson<FirmBrandingDto>(doc.BrandingJson),
            parties = DeserializeJson<List<DocumentPartyDto>>(doc.PartiesJson),
            clauseKeys = DeserializeJson<List<string>>(doc.ClauseKeysJson)
        });
    }

    // ===== DRAFTS ENDPOINTS =====

    [HttpGet("drafts")]
    public async Task<ActionResult<IEnumerable<DocumentDraftDto>>> GetDrafts()
    {
        var userName = User.Identity?.Name ?? string.Empty;
        
        var drafts = await _context.DocumentDrafts
            .Where(d => !d.IsDeleted && d.CreatedBy == userName)
            .OrderByDescending(d => d.LastModifiedAt)
            .Select(d => new
            {
                d.Id,
                d.TemplateType,
                d.CaseCode,
                d.CustomerId,
                d.Format,
                d.Scope,
                d.FeeTerms,
                d.Subject,
                d.Statement,
                d.AiInstructions,
                d.PreviewContent,
                d.DocumentTitle,
                d.DocumentReference,
                d.DocumentCategory,
                d.DocumentNotes,
                d.BrandingJson,
                d.PartiesJson,
                d.ClauseKeysJson,
                d.SaveToCase,
                d.CreatedBy,
                d.CreatedAt,
                d.LastModifiedAt,
                d.DraftName
            })
            .ToListAsync();

        return Ok(drafts.Select(d => new DocumentDraftDto
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
        }));
    }

   [HttpGet("drafts/{id}")]
    public async Task<ActionResult<DocumentDraftDto>> GetDraftById(int id)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        
        var draft = await _context.DocumentDrafts
            .Where(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName)
            .Select(d => new
            {
                d.Id,
                d.TemplateType,
                d.CaseCode,
                d.CustomerId,
                d.Format,
                d.Scope,
                d.FeeTerms,
                d.Subject,
                d.Statement,
                d.AiInstructions,
                d.PreviewContent,
                d.DocumentTitle,
                d.DocumentReference,
                d.DocumentCategory,
                d.DocumentNotes,
                d.BrandingJson,
                d.PartiesJson,
                d.ClauseKeysJson,
                d.SaveToCase,
                d.CreatedBy,
                d.CreatedAt,
                d.LastModifiedAt,
                d.DraftName
            })
            .FirstOrDefaultAsync();

        if (draft == null)
        {
            return NotFound(new { message = "Draft not found" });
        }

        return Ok(new DocumentDraftDto
        {
            Id = draft.Id,
            TemplateType = draft.TemplateType,
            CaseCode = draft.CaseCode,
            CustomerId = draft.CustomerId,
            Format = draft.Format,
            Scope = draft.Scope,
            FeeTerms = draft.FeeTerms,
            Subject = draft.Subject,
            Statement = draft.Statement,
            AiInstructions = draft.AiInstructions,
            PreviewContent = draft.PreviewContent,
            DocumentTitle = draft.DocumentTitle,
            DocumentReference = draft.DocumentReference,
            DocumentCategory = draft.DocumentCategory,
            DocumentNotes = draft.DocumentNotes,
            Branding = DeserializeJson<FirmBrandingDto>(draft.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(draft.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(draft.ClauseKeysJson),
            SaveToCase = draft.SaveToCase,
            CreatedBy = draft.CreatedBy,
            CreatedAt = draft.CreatedAt,
            LastModifiedAt = draft.LastModifiedAt,
            DraftName = draft.DraftName
        });
    }

    [HttpPost("drafts")]
    public async Task<ActionResult<DocumentDraftDto>> CreateDraft([FromBody] CreateDraftDto dto)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var now = DateTime.UtcNow;

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
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetDraftById), new { id = draft.Id }, new DocumentDraftDto
        {
            Id = draft.Id,
            TemplateType = draft.TemplateType,
            CaseCode = draft.CaseCode,
            CustomerId = draft.CustomerId,
            Format = draft.Format,
            Scope = draft.Scope,
            FeeTerms = draft.FeeTerms,
            Subject = draft.Subject,
            Statement = draft.Statement,
            AiInstructions = draft.AiInstructions,
            PreviewContent = draft.PreviewContent,
            DocumentTitle = draft.DocumentTitle,
            DocumentReference = draft.DocumentReference,
            DocumentCategory = draft.DocumentCategory,
            DocumentNotes = draft.DocumentNotes,
            Branding = DeserializeJson<FirmBrandingDto>(draft.BrandingJson),
            Parties = DeserializeJson<List<DocumentPartyDto>>(draft.PartiesJson),
            ClauseKeys = DeserializeJson<List<string>>(draft.ClauseKeysJson),
            SaveToCase = draft.SaveToCase,
            CreatedBy = draft.CreatedBy,
            CreatedAt = draft.CreatedAt,
            LastModifiedAt = draft.LastModifiedAt,
            DraftName = draft.DraftName
        });
    }

    [HttpPut("drafts/{id}")]
    public async Task<IActionResult> UpdateDraft(int id, [FromBody] UpdateDraftDto dto)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        
        var draft = await _context.DocumentDrafts
            .FirstOrDefaultAsync(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName);

        if (draft == null)
        {
            return NotFound(new { message = "Draft not found" });
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
        draft.LastModifiedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("drafts/{id}")]
    public async Task<IActionResult> DeleteDraft(int id)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        
        var draft = await _context.DocumentDrafts
            .FirstOrDefaultAsync(d => d.Id == id && !d.IsDeleted && d.CreatedBy == userName);

        if (draft == null)
        {
            return NotFound(new { message = "Draft not found" });
        }

        draft.IsDeleted = true;
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // ===== VERSION TRACKING ENDPOINTS =====

    [HttpGet("history/{id}/versions")]
    public async Task<ActionResult<DocumentVersionChainDto>> GetVersionChain(int id)
    {
        var doc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync();

        if (doc == null)
        {
            return NotFound(new { message = "Document not found" });
        }

        var rootId = doc.ParentDocumentId ?? doc.Id;

        var allVersions = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .OrderBy(d => d.Version)
            .Select(d => new
            {
                d.Id,
                d.Version,
                d.GeneratedBy,
                d.GeneratedAt,
                d.ParentDocumentId,
                d.DocumentTitle,
                d.TemplateType
            })
            .ToListAsync();

        var latestVersion = allVersions.MaxBy(v => v.Version);
        var latestId = latestVersion?.Id ?? rootId;

        var versions = allVersions.Select(v => new DocumentVersionDto
        {
            Id = v.Id,
            Version = v.Version,
            GeneratedBy = v.GeneratedBy,
            GeneratedAt = v.GeneratedAt,
            ParentDocumentId = v.ParentDocumentId,
            IsCurrent = v.Id == latestId
        }).ToList();

        return Ok(new DocumentVersionChainDto
        {
            RootDocumentId = rootId,
            DocumentTitle = doc.DocumentTitle ?? doc.TemplateType,
            TemplateType = doc.TemplateType,
            TotalVersions = versions.Count,
            Versions = versions
        });
    }

    [HttpPost("history/{id}/regenerate")]
    public async Task<ActionResult<GeneratedDocumentResponseDto>> RegenerateAsNewVersion(int id, [FromBody] RegenerateDocumentDto? dto = null)
    {
        var originalDoc = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync();

        if (originalDoc == null)
        {
            return NotFound(new { message = "Original document not found" });
        }

        var rootId = originalDoc.ParentDocumentId ?? originalDoc.Id;
        var maxVersion = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .MaxAsync(d => d.Version);

        var newContent = originalDoc.GeneratedContent;
        var branding = dto?.Branding ?? DeserializeJson<FirmBrandingDto>(originalDoc.BrandingJson);
        var parties = dto?.Parties ?? DeserializeJson<List<DocumentPartyDto>>(originalDoc.PartiesJson);
        var clauseKeys = dto?.ClauseKeys ?? DeserializeJson<List<string>>(originalDoc.ClauseKeysJson);

        var bytes = LegalTemplateGenerator.BuildOutput(newContent, originalDoc.Format);
        var ext = LegalTemplateGenerator.GetFileExtension(originalDoc.Format);
        var fileName = $"{originalDoc.TemplateType}-v{maxVersion + 1}-{DateTime.UtcNow:yyyyMMddHHmmss}.{ext}";

        int? fileId = null;

        if (dto?.SaveToCase == true && originalDoc.CaseCode.HasValue)
        {
            var result = await SaveDocumentToCaseAsync(
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
                ext
            );
            fileId = result.FileId;
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
            GeneratedBy = User.Identity?.Name ?? "System",
            GeneratedAt = DateTime.UtcNow,
            Version = maxVersion + 1,
            ParentDocumentId = rootId
        };

        _context.GeneratedDocuments.Add(newVersionDoc);
        await _context.SaveChangesAsync();

        return Ok(new GeneratedDocumentResponseDto
        {
            FileId = fileId,
            FileName = fileName,
            SavedToCase = dto?.SaveToCase ?? false
        });
    }

    [HttpPost("history/{id}/restore")]
    public async Task<ActionResult<RestoreVersionResponseDto>> RestoreVersion(int id)
    {
        var docToRestore = await _context.GeneratedDocuments
            .Where(d => d.Id == id && !d.IsDeleted)
            .FirstOrDefaultAsync();

        if (docToRestore == null)
        {
            return NotFound(new { message = "Document version not found" });
        }

        var rootId = docToRestore.ParentDocumentId ?? docToRestore.Id;
        var maxVersion = await _context.GeneratedDocuments
            .Where(d => !d.IsDeleted && (d.Id == rootId || d.ParentDocumentId == rootId))
            .MaxAsync(d => d.Version);

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
            GeneratedBy = User.Identity?.Name ?? "System",
            GeneratedAt = DateTime.UtcNow,
            Version = maxVersion + 1,
            ParentDocumentId = rootId
        };

        _context.GeneratedDocuments.Add(restoredDoc);
        await _context.SaveChangesAsync();

        return Ok(new RestoreVersionResponseDto
        {
            RestoredDocumentId = restoredDoc.Id,
            NewVersion = restoredDoc.Version,
            Message = $"Document restored as version {restoredDoc.Version}"
        });
    }
}
