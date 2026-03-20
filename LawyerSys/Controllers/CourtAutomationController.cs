using System.Text;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Resources;
using LawyerSys.Services.Reporting;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class CourtAutomationController : ControllerBase
{
    private const string TriggerDateAnchor = "TriggerDate";
    private const string HearingDateAnchor = "HearingDate";

    private readonly LegacyDbContext _context;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CourtAutomationController(LegacyDbContext context, IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _localizer = localizer;
    }

    [HttpGet("packs")]
    public async Task<ActionResult<IEnumerable<CourtJurisdictionPackDto>>> GetPacks([FromQuery] string? language = "en")
    {
        var lang = NormalizeLanguage(language);
        var packs = await _context.CourtAutomationPacks
            .Where(p => p.IsActive)
            .OrderBy(p => p.NameEn)
            .Select(p => new CourtJurisdictionPackDto
            {
                Key = p.Key,
                Name = lang == "ar" ? p.NameAr : p.NameEn,
                Description = lang == "ar" ? p.DescriptionAr : p.DescriptionEn,
                JurisdictionCode = p.JurisdictionCode,
                Forms = p.FormTemplates
                    .Where(f => f.IsActive)
                    .OrderBy(f => f.NameEn)
                    .Select(f => new CourtFormTemplateDto
                    {
                        Key = f.Key,
                        Name = lang == "ar" ? f.NameAr : f.NameEn,
                        Description = lang == "ar" ? f.DescriptionAr : f.DescriptionEn
                    }).ToList(),
                DeadlineRules = p.DeadlineRules
                    .Where(r => r.IsActive)
                    .OrderBy(r => r.NameEn)
                    .Select(r => new CourtDeadlineRuleDto
                    {
                        Key = r.Key,
                        Name = lang == "ar" ? r.NameAr : r.NameEn,
                        Description = lang == "ar" ? r.DescriptionAr : r.DescriptionEn,
                        OffsetDays = r.OffsetDays,
                        Anchor = r.Anchor
                    }).ToList(),
                FilingChannels = p.FilingChannels
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.ChannelCode)
                    .Select(c => c.ChannelCode)
                    .ToList()
            })
            .ToListAsync();

        return Ok(packs);
    }

    [HttpGet("packs/{packKey}")]
    public async Task<ActionResult<CourtJurisdictionPackDto>> GetPack(string packKey, [FromQuery] string? language = "en")
    {
        var pack = await GetPackDtoAsync(packKey, NormalizeLanguage(language));
        if (pack is null)
        {
            return NotFound(new { message = _localizer["JurisdictionPackNotFound"].Value });
        }

        return Ok(pack);
    }

    [HttpPost("calculate-deadlines")]
    public async Task<ActionResult<CalculateCourtDeadlinesResponseDto>> CalculateDeadlines([FromBody] CalculateCourtDeadlinesRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(request.Language);
        var pack = await _context.CourtAutomationPacks
            .Include(p => p.DeadlineRules)
            .FirstOrDefaultAsync(p => p.IsActive && p.Key == request.PackKey);
        if (pack is null)
        {
            return BadRequest(new { message = _localizer["InvalidJurisdictionPackKey"].Value });
        }

        var triggerDate = request.TriggerDate == default ? DateOnly.FromDateTime(DateTime.UtcNow.Date) : request.TriggerDate;
        DateOnly? hearingDate = request.HearingDate;

        if (request.CaseCode.HasValue)
        {
            var exists = await _context.Cases.AnyAsync(c => c.Code == request.CaseCode.Value);
            if (!exists)
            {
                return NotFound(new { message = _localizer["CaseNotFound"].Value });
            }

            if (!hearingDate.HasValue)
            {
                hearingDate = await _context.Cases_Sitings
                    .Where(cs => cs.Case_Code == request.CaseCode.Value)
                    .Select(cs => (DateOnly?)cs.Siting.Siting_Date)
                    .OrderBy(d => d)
                    .FirstOrDefaultAsync();
            }
        }

        var deadlines = BuildDeadlinesFromRules(pack.DeadlineRules.Where(r => r.IsActive), triggerDate, hearingDate, language);
        return Ok(new CalculateCourtDeadlinesResponseDto
        {
            PackKey = request.PackKey,
            CaseCode = request.CaseCode,
            TriggerDate = triggerDate,
            HearingDate = hearingDate,
            Deadlines = deadlines
        });
    }

    [HttpPost("generate-form")]
    public async Task<IActionResult> GenerateForm([FromBody] GenerateCourtFormRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(request.Language);
        var pack = await _context.CourtAutomationPacks
            .Include(p => p.FormTemplates)
            .FirstOrDefaultAsync(p => p.IsActive && p.Key == request.PackKey);
        if (pack is null)
        {
            return BadRequest(new { message = _localizer["PackNotFound"].Value });
        }

        var form = pack.FormTemplates.FirstOrDefault(f => f.IsActive && f.Key == request.FormKey);
        if (form is null)
        {
            return BadRequest(new { message = _localizer["FormNotFoundInPack"].Value });
        }

        var variables = await BuildFormVariablesAsync(request);
        var content = RenderTemplate(language == "ar" ? form.BodyAr : form.BodyEn, variables);
        var formDisplayName = language == "ar" ? form.NameAr : form.NameEn;

        var generatedAt = DateTime.UtcNow;
        var isPdf = string.Equals(request.Format, "pdf", StringComparison.OrdinalIgnoreCase);
        var ext = isPdf ? "pdf" : "txt";
        var contentType = isPdf ? "application/pdf" : "text/plain";
        var fileName = $"{request.PackKey}-{request.FormKey}-{generatedAt:yyyyMMddHHmmss}.{ext}";

        if (isPdf)
        {
            var lines = content.Split('\n').Select(x => x.TrimEnd('\r'));
            var bytes = ReportExportBuilder.BuildSimplePdf(formDisplayName, lines);
            return File(bytes, contentType, fileName);
        }

        return File(Encoding.UTF8.GetBytes(content), contentType, fileName);
    }

    [HttpPost("filings/submit")]
    public async Task<ActionResult<CourtFilingSubmissionDto>> SubmitFiling([FromBody] SubmitCourtFilingRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(request.Language);
        var pack = await _context.CourtAutomationPacks
            .Include(p => p.FormTemplates)
            .Include(p => p.FilingChannels)
            .FirstOrDefaultAsync(p => p.IsActive && p.Key == request.PackKey);
        if (pack is null)
        {
            return BadRequest(new { message = _localizer["PackNotFound"].Value });
        }

        var form = pack.FormTemplates.FirstOrDefault(f => f.IsActive && f.Key == request.FormKey);
        if (form is null)
        {
            return BadRequest(new { message = _localizer["FormNotFoundInPack"].Value });
        }

        var availableChannels = pack.FilingChannels.Where(c => c.IsActive).ToList();
        var channel = string.IsNullOrWhiteSpace(request.FilingChannel)
            ? availableChannels.Select(c => c.ChannelCode).FirstOrDefault() ?? "Manual"
            : request.FilingChannel.Trim();
        if (!availableChannels.Any(c => string.Equals(c.ChannelCode, channel, StringComparison.OrdinalIgnoreCase)))
        {
            return BadRequest(new { message = _localizer["InvalidFilingChannel"].Value });
        }

        if (request.CaseCode.HasValue)
        {
            var caseExists = await _context.Cases.AnyAsync(c => c.Code == request.CaseCode.Value);
            if (!caseExists)
            {
                return NotFound(new { message = _localizer["CaseNotFound"].Value });
            }
        }

        if (request.CourtId.HasValue)
        {
            var courtExists = await _context.Courts.AnyAsync(c => c.Id == request.CourtId.Value);
            if (!courtExists)
            {
                return NotFound(new { message = _localizer["CourtNotFound"].Value });
            }
        }

        var now = DateTime.UtcNow;
        var entity = new CourtAutomationFilingSubmission
        {
            SubmissionId = Guid.NewGuid().ToString("N"),
            PackKey = request.PackKey,
            FormKey = request.FormKey,
            FilingChannel = channel,
            CaseCode = request.CaseCode,
            CourtId = request.CourtId,
            DueDate = request.DueDate,
            Notes = request.Notes,
            Status = "Submitted",
            SubmittedAt = now,
            LastStatusAt = now,
            NextCheckAt = now.AddMinutes(5),
            ExternalReference = $"{request.PackKey.ToUpperInvariant()}-{now:yyyyMMddHHmmss}",
            Message = language == "ar"
                ? "تم إرسال الطلب إلى قناة الإيداع."
                : "Filing request submitted to integration channel."
        };

        _context.CourtAutomationFilingSubmissions.Add(entity);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetFilingSubmission), new { submissionId = entity.SubmissionId }, MapSubmission(entity));
    }

    [HttpGet("filings")]
    public async Task<ActionResult<IEnumerable<CourtFilingSubmissionDto>>> GetFilings([FromQuery] int? caseCode = null, [FromQuery] string? packKey = null)
    {
        var query = _context.CourtAutomationFilingSubmissions.AsQueryable();
        if (caseCode.HasValue)
        {
            query = query.Where(x => x.CaseCode == caseCode.Value);
        }

        if (!string.IsNullOrWhiteSpace(packKey))
        {
            query = query.Where(x => x.PackKey == packKey);
        }

        var entities = await query
            .OrderByDescending(x => x.SubmittedAt)
            .Take(100)
            .ToListAsync();

        var changed = false;
        foreach (var item in entities)
        {
            changed |= AdvanceSubmissionStatus(item);
        }

        if (changed)
        {
            await _context.SaveChangesAsync();
        }

        return Ok(entities.Select(MapSubmission).ToList());
    }

    [HttpGet("filings/{submissionId}")]
    public async Task<ActionResult<CourtFilingSubmissionDto>> GetFilingSubmission(string submissionId)
    {
        var entity = await _context.CourtAutomationFilingSubmissions
            .FirstOrDefaultAsync(x => x.SubmissionId == submissionId);
        if (entity is null)
        {
            return NotFound(new { message = _localizer["FilingSubmissionNotFound"].Value });
        }

        if (AdvanceSubmissionStatus(entity))
        {
            await _context.SaveChangesAsync();
        }

        return Ok(MapSubmission(entity));
    }

    private async Task<CourtJurisdictionPackDto?> GetPackDtoAsync(string packKey, string language)
    {
        var pack = await _context.CourtAutomationPacks
            .Where(p => p.IsActive && p.Key == packKey)
            .Select(p => new CourtJurisdictionPackDto
            {
                Key = p.Key,
                Name = language == "ar" ? p.NameAr : p.NameEn,
                Description = language == "ar" ? p.DescriptionAr : p.DescriptionEn,
                JurisdictionCode = p.JurisdictionCode,
                Forms = p.FormTemplates
                    .Where(f => f.IsActive)
                    .OrderBy(f => f.NameEn)
                    .Select(f => new CourtFormTemplateDto
                    {
                        Key = f.Key,
                        Name = language == "ar" ? f.NameAr : f.NameEn,
                        Description = language == "ar" ? f.DescriptionAr : f.DescriptionEn
                    }).ToList(),
                DeadlineRules = p.DeadlineRules
                    .Where(r => r.IsActive)
                    .OrderBy(r => r.NameEn)
                    .Select(r => new CourtDeadlineRuleDto
                    {
                        Key = r.Key,
                        Name = language == "ar" ? r.NameAr : r.NameEn,
                        Description = language == "ar" ? r.DescriptionAr : r.DescriptionEn,
                        OffsetDays = r.OffsetDays,
                        Anchor = r.Anchor
                    }).ToList(),
                FilingChannels = p.FilingChannels
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.ChannelCode)
                    .Select(c => c.ChannelCode)
                    .ToList()
            })
            .FirstOrDefaultAsync();

        return pack;
    }

    private static IReadOnlyList<CourtDeadlineItemDto> BuildDeadlinesFromRules(
        IEnumerable<CourtAutomationDeadlineRule> rules,
        DateOnly triggerDate,
        DateOnly? hearingDate,
        string language)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var result = new List<CourtDeadlineItemDto>();

        foreach (var rule in rules)
        {
            var anchor = string.Equals(rule.Anchor, HearingDateAnchor, StringComparison.OrdinalIgnoreCase) && hearingDate.HasValue
                ? hearingDate.Value
                : triggerDate;
            var dueDate = anchor.AddDays(rule.OffsetDays);
            var priority = dueDate < today ? "High" : dueDate <= today.AddDays(2) ? "High" : dueDate <= today.AddDays(7) ? "Medium" : "Low";
            var name = language == "ar" ? rule.NameAr : rule.NameEn;
            var desc = language == "ar" ? rule.DescriptionAr : rule.DescriptionEn;
            var anchorLabel = string.Equals(rule.Anchor, HearingDateAnchor, StringComparison.OrdinalIgnoreCase)
                ? (language == "ar" ? "تاريخ الجلسة" : "hearing date")
                : (language == "ar" ? "تاريخ البدء" : "trigger date");

            result.Add(new CourtDeadlineItemDto
            {
                RuleKey = rule.Key,
                Name = name,
                DueDate = dueDate,
                Priority = priority,
                Notes = $"{desc} ({anchorLabel})"
            });
        }

        return result
            .OrderBy(x => PriorityRank(x.Priority))
            .ThenBy(x => x.DueDate)
            .ToList();
    }

    private static int PriorityRank(string priority) => priority switch
    {
        "High" => 0,
        "Medium" => 1,
        _ => 2
    };

    private static string NormalizeLanguage(string? language)
        => !string.IsNullOrWhiteSpace(language) && language.StartsWith("ar", StringComparison.OrdinalIgnoreCase) ? "ar" : "en";

    private static bool AdvanceSubmissionStatus(CourtAutomationFilingSubmission submission)
    {
        var changed = false;
        var now = DateTime.UtcNow;
        if (submission.Status == "Submitted" && submission.NextCheckAt.HasValue && now >= submission.NextCheckAt.Value)
        {
            submission.Status = "InReview";
            submission.LastStatusAt = now;
            submission.NextCheckAt = now.AddMinutes(20);
            submission.Message = "Filing is being reviewed by the external channel.";
            changed = true;
        }
        else if (submission.Status == "InReview" && submission.NextCheckAt.HasValue && now >= submission.NextCheckAt.Value)
        {
            submission.Status = "Accepted";
            submission.LastStatusAt = now;
            submission.NextCheckAt = null;
            submission.Message = "Filing accepted by channel and queued for court processing.";
            changed = true;
        }

        if (submission.DueDate.HasValue && submission.DueDate.Value < DateOnly.FromDateTime(now.Date) && submission.Status != "Accepted")
        {
            var overdueMessage = "Filing due date has passed. Escalate with urgent follow-up.";
            if (!string.Equals(submission.Message, overdueMessage, StringComparison.Ordinal))
            {
                submission.Message = overdueMessage;
                changed = true;
            }
        }

        return changed;
    }

    private static string RenderTemplate(string template, IDictionary<string, string> variables)
    {
        foreach (var kv in variables)
        {
            template = template.Replace($"{{{{{kv.Key}}}}}", kv.Value ?? string.Empty, StringComparison.OrdinalIgnoreCase);
        }

        return template;
    }

    private static CourtFilingSubmissionDto MapSubmission(CourtAutomationFilingSubmission entity)
        => new()
        {
            SubmissionId = entity.SubmissionId,
            PackKey = entity.PackKey,
            FormKey = entity.FormKey,
            FilingChannel = entity.FilingChannel,
            CaseCode = entity.CaseCode,
            CourtId = entity.CourtId,
            DueDate = entity.DueDate,
            Status = entity.Status,
            Message = entity.Message,
            ExternalReference = entity.ExternalReference,
            SubmittedAt = entity.SubmittedAt,
            LastStatusAt = entity.LastStatusAt,
            NextCheckAt = entity.NextCheckAt,
            Notes = entity.Notes
        };

    private async Task<Dictionary<string, string>> BuildFormVariablesAsync(GenerateCourtFormRequestDto request)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Today"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            ["CaseCode"] = request.CaseCode?.ToString() ?? "N/A",
            ["CaseType"] = "N/A",
            ["CourtName"] = "N/A",
            ["CustomerName"] = "N/A",
            ["Subject"] = "N/A",
            ["Facts"] = "N/A",
            ["Requests"] = "N/A",
            ["Grounds"] = "N/A",
            ["Reference"] = "N/A",
            ["Scope"] = "N/A"
        };

        if (request.CaseCode.HasValue)
        {
            var caseEntity = await _context.Cases
                .FirstOrDefaultAsync(c => c.Code == request.CaseCode.Value);

            if (caseEntity is not null)
            {
                result["CaseCode"] = caseEntity.Code.ToString();
                result["CaseType"] = caseEntity.Invition_Type;
                result["Subject"] = caseEntity.Invition_Type;
                result["Facts"] = caseEntity.Invitions_Statment;
                result["Requests"] = string.IsNullOrWhiteSpace(caseEntity.Notes) ? "As per claim." : caseEntity.Notes;
                result["Grounds"] = string.IsNullOrWhiteSpace(caseEntity.Notes) ? "As per legal basis." : caseEntity.Notes;
                result["Reference"] = $"CASE-{caseEntity.Code}";
                result["Scope"] = caseEntity.Invition_Type;
            }

            var courtName = await _context.Cases_Courts
                .Where(cc => cc.Case_Code == request.CaseCode.Value)
                .Select(cc => cc.Court.Name)
                .FirstOrDefaultAsync();
            if (!string.IsNullOrWhiteSpace(courtName))
            {
                result["CourtName"] = courtName;
            }
        }

        int? customerId = request.CustomerId;
        if (!customerId.HasValue && request.CaseCode.HasValue)
        {
            customerId = await _context.Custmors_Cases
                .Where(cc => cc.Case_Id == request.CaseCode.Value)
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
                result["CustomerName"] = customerName;
            }
        }

        if (request.Variables is not null)
        {
            foreach (var item in request.Variables)
            {
                result[item.Key] = item.Value;
            }
        }

        return result;
    }
}
