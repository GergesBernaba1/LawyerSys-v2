using System.Text.RegularExpressions;
using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Services.AIAssistant;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class AIAssistantController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IAiAssistantTextService _aiTextService;

    public AIAssistantController(LegacyDbContext context, IAiAssistantTextService aiTextService)
    {
        _context = context;
        _aiTextService = aiTextService;
    }

    [HttpPost("summarize")]
    public async Task<ActionResult<AiSummaryResponseDto>> Summarize([FromBody] AiSummaryRequestDto request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(request.Language);
        var maxPoints = Math.Clamp(request.MaxKeyPoints, 1, 8);
        var fallback = BuildFallbackSummary(request.Text, maxPoints, language);

        var systemPrompt = language == "ar"
            ? "أنت مساعد قانوني ثنائي اللغة. قدم تلخيصاً عملياً للنص بدون اختلاق معلومات."
            : "You are a bilingual legal assistant. Summarize the provided text accurately and avoid fabrications.";
        var userPrompt = language == "ar"
            ? $"لخص النص التالي في فقرة قصيرة ثم أضف نقاطاً رئيسية (من 3 إلى {maxPoints})، وكل نقطة تبدأ بـ \"- \".\n\n{request.Text}"
            : $"Summarize the text below in one short paragraph, then add 3 to {maxPoints} key points. Each key point must start with '- '.\n\n{request.Text}";

        var aiResult = await _aiTextService.TryGenerateAsync(systemPrompt, userPrompt, cancellationToken);
        if (string.IsNullOrWhiteSpace(aiResult))
        {
            return Ok(fallback);
        }

        var parsed = ParseSummaryResult(aiResult, maxPoints);
        return Ok(new AiSummaryResponseDto
        {
            Language = language,
            Summary = string.IsNullOrWhiteSpace(parsed.Summary) ? fallback.Summary : parsed.Summary,
            KeyPoints = parsed.KeyPoints.Count > 0 ? parsed.KeyPoints : fallback.KeyPoints,
            UsedAiModel = true
        });
    }

    [HttpPost("draft")]
    public async Task<ActionResult<AiDraftResponseDto>> Draft([FromBody] AiDraftRequestDto request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(request.Language);
        var fallbackDraft = BuildFallbackDraft(request, language);
        var disclaimer = language == "ar"
            ? "مخرجات أولية للمراجعة القانونية الداخلية وليست استشارة قانونية نهائية."
            : "Initial draft for internal legal review only; not final legal advice.";

        var systemPrompt = language == "ar"
            ? "أنت مساعد صياغة قانونية. اكتب مسودة عملية ومنظمة بصياغة مهنية."
            : "You are a legal drafting assistant. Write a practical, well-structured professional draft.";
        var userPrompt = language == "ar"
            ? $"نوع المسودة: {request.DraftType}\nالتعليمات: {request.Instructions}\nالسياق: {request.Context ?? "لا يوجد"}\n\nقدّم نص المسودة مباشرة."
            : $"Draft type: {request.DraftType}\nInstructions: {request.Instructions}\nContext: {request.Context ?? "N/A"}\n\nProvide the draft text directly.";

        var aiDraft = await _aiTextService.TryGenerateAsync(systemPrompt, userPrompt, cancellationToken);
        return Ok(new AiDraftResponseDto
        {
            Language = language,
            DraftType = request.DraftType,
            DraftText = string.IsNullOrWhiteSpace(aiDraft) ? fallbackDraft : aiDraft.Trim(),
            Disclaimer = disclaimer,
            UsedAiModel = !string.IsNullOrWhiteSpace(aiDraft)
        });
    }

    [HttpGet("task-deadline-suggestions")]
    public async Task<ActionResult<AiTaskSuggestionsResponseDto>> GetTaskDeadlineSuggestions([FromQuery] AiTaskSuggestionsQueryDto query, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var language = NormalizeLanguage(query.Language);
        var daysWindow = Math.Clamp(query.Days, 3, 45);
        var maxSuggestions = Math.Clamp(query.MaxSuggestions, 3, 20);
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var nowUtc = DateTime.UtcNow;
        var limitDate = today.AddDays(daysWindow);

        var suggestions = new List<AiTaskSuggestionItemDto>();

        var tasks = await _context.AdminstrativeTasks
            .Where(t => t.Task_Date <= limitDate)
            .OrderBy(t => t.Task_Date)
            .Take(250)
            .ToListAsync(cancellationToken);

        foreach (var task in tasks)
        {
            var taskDateTime = DateTime.SpecifyKind(task.Task_Date.ToDateTime(TimeOnly.MinValue), DateTimeKind.Utc);
            var reminderLeadHours = (taskDateTime - task.Task_Reminder_Date).TotalHours;

            if (task.Task_Date < today)
            {
                suggestions.Add(new AiTaskSuggestionItemDto
                {
                    Title = language == "ar"
                        ? $"متابعة فورية للمهمة المتأخرة: {task.Task_Name}"
                        : $"Immediate follow-up for overdue task: {task.Task_Name}",
                    SuggestedDueDate = today,
                    SuggestedReminderAt = nowUtc.AddHours(1),
                    Priority = "High",
                    Rationale = language == "ar"
                        ? $"المهمة متأخرة منذ {task.Task_Date:yyyy-MM-dd}. يُفضل إعادة الجدولة وتحديد مسؤول التنفيذ."
                        : $"Task has been overdue since {task.Task_Date:yyyy-MM-dd}. Re-plan and assign accountable owner.",
                    SourceType = "Task",
                    SourceId = task.Id
                });
                continue;
            }

            if (reminderLeadHours < 12)
            {
                var suggestedDue = task.Task_Date.AddDays(-1) < today ? today : task.Task_Date.AddDays(-1);
                var suggestedReminderAt = DateTime.SpecifyKind(suggestedDue.ToDateTime(new TimeOnly(9, 0)), DateTimeKind.Utc);
                if (suggestedReminderAt < nowUtc)
                {
                    suggestedReminderAt = nowUtc.AddHours(1);
                }

                suggestions.Add(new AiTaskSuggestionItemDto
                {
                    Title = language == "ar"
                        ? $"تقديم تذكير المهمة: {task.Task_Name}"
                        : $"Move reminder earlier: {task.Task_Name}",
                    SuggestedDueDate = suggestedDue,
                    SuggestedReminderAt = suggestedReminderAt,
                    Priority = "Medium",
                    Rationale = language == "ar"
                        ? "وقت التذكير الحالي قريب جداً من موعد التنفيذ. يوصى بتذكير مبكر لتحسين الالتزام."
                        : "Current reminder is too close to due time. Earlier reminder improves completion reliability.",
                    SourceType = "Task",
                    SourceId = task.Id
                });
            }
        }

        var hearings = await _context.Cases_Sitings
            .Where(cs => cs.Siting.Siting_Date >= today && cs.Siting.Siting_Date <= limitDate)
            .Select(cs => new
            {
                cs.Case_Code,
                cs.Siting_Id,
                cs.Siting.Siting_Date,
                cs.Siting.Siting_Notification,
                cs.Siting.Judge_Name
            })
            .ToListAsync(cancellationToken);

        foreach (var hearing in hearings)
        {
            var prepDue = hearing.Siting_Date.AddDays(-2) < today ? today : hearing.Siting_Date.AddDays(-2);
            var reminderAt = DateTime.SpecifyKind(prepDue.ToDateTime(new TimeOnly(9, 0)), DateTimeKind.Utc);
            if (reminderAt < nowUtc)
            {
                reminderAt = nowUtc.AddHours(1);
            }

            var isNear = hearing.Siting_Date <= today.AddDays(3);
            suggestions.Add(new AiTaskSuggestionItemDto
            {
                Title = language == "ar"
                    ? $"تحضير ملف جلسة القضية #{hearing.Case_Code}"
                    : $"Prepare hearing bundle for case #{hearing.Case_Code}",
                SuggestedDueDate = prepDue,
                SuggestedReminderAt = reminderAt,
                Priority = isNear ? "High" : "Medium",
                Rationale = language == "ar"
                    ? $"جلسة أمام القاضي {hearing.Judge_Name} بتاريخ {hearing.Siting_Date:yyyy-MM-dd}. يُنصح بتجهيز المستندات والمرافعة."
                    : $"Hearing before Judge {hearing.Judge_Name} on {hearing.Siting_Date:yyyy-MM-dd}. Prepare exhibits and argument notes.",
                SourceType = "Hearing",
                SourceId = hearing.Siting_Id,
                CaseCode = hearing.Case_Code
            });
        }

        if (suggestions.Count == 0)
        {
            var due = today.AddDays(1);
            suggestions.Add(new AiTaskSuggestionItemDto
            {
                Title = language == "ar"
                    ? "مراجعة أسبوعية للمهام والمواعيد"
                    : "Weekly docket and task review",
                SuggestedDueDate = due,
                SuggestedReminderAt = DateTime.SpecifyKind(due.ToDateTime(new TimeOnly(9, 0)), DateTimeKind.Utc),
                Priority = "Low",
                Rationale = language == "ar"
                    ? "لا توجد عناصر عاجلة ضمن النطاق المحدد. المراجعة الوقائية تحافظ على الانضباط التشغيلي."
                    : "No urgent items detected in the selected range. Preventive review keeps execution disciplined.",
                SourceType = "System"
            });
        }

        var ranked = suggestions
            .OrderBy(s => PriorityRank(s.Priority))
            .ThenBy(s => s.SuggestedDueDate)
            .Take(maxSuggestions)
            .ToList();

        return Ok(new AiTaskSuggestionsResponseDto
        {
            Language = language,
            GeneratedForDate = today,
            DaysWindow = daysWindow,
            Suggestions = ranked,
            UsedAiModel = false
        });
    }

    private static int PriorityRank(string priority) => priority switch
    {
        "High" => 0,
        "Medium" => 1,
        _ => 2
    };

    private static string NormalizeLanguage(string? language)
    {
        if (!string.IsNullOrWhiteSpace(language) && language.StartsWith("ar", StringComparison.OrdinalIgnoreCase))
        {
            return "ar";
        }

        return "en";
    }

    private static AiSummaryResponseDto BuildFallbackSummary(string text, int maxPoints, string language)
    {
        var cleaned = Regex.Replace(text.Trim(), @"\s+", " ");
        if (string.IsNullOrWhiteSpace(cleaned))
        {
            cleaned = language == "ar" ? "لا يوجد نص كافٍ للتلخيص." : "No text provided for summarization.";
        }

        var sentences = Regex.Split(cleaned, @"(?<=[\.\!\?؟])\s+")
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => s.Trim())
            .ToList();

        var summary = sentences.Count switch
        {
            0 => cleaned,
            1 => sentences[0],
            _ => string.Join(" ", sentences.Take(2))
        };

        if (summary.Length > 900)
        {
            summary = summary[..900] + "...";
        }

        var keyPoints = sentences
            .Take(Math.Max(maxPoints, 3))
            .Select(s => s.Trim().TrimEnd('.'))
            .Where(s => s.Length > 10)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(maxPoints)
            .ToList();

        if (keyPoints.Count == 0)
        {
            keyPoints.Add(language == "ar" ? "يتطلب النص مراجعة قانونية تفصيلية." : "The text requires detailed legal review.");
        }

        return new AiSummaryResponseDto
        {
            Language = language,
            Summary = summary,
            KeyPoints = keyPoints,
            UsedAiModel = false
        };
    }

    private static (string Summary, List<string> KeyPoints) ParseSummaryResult(string aiText, int maxPoints)
    {
        var lines = aiText
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();

        var bullets = lines
            .Where(l => l.StartsWith("- ") || l.StartsWith("• ") || Regex.IsMatch(l, @"^\d+[\.\)]\s+"))
            .Select(l => Regex.Replace(l, @"^(-|•|\d+[\.\)])\s*", "").Trim())
            .Where(l => !string.IsNullOrWhiteSpace(l))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(maxPoints)
            .ToList();

        var summaryLines = lines
            .Where(l => !l.StartsWith("- ") && !l.StartsWith("• ") && !Regex.IsMatch(l, @"^\d+[\.\)]\s+"))
            .Where(l => !l.StartsWith("summary", StringComparison.OrdinalIgnoreCase))
            .Where(l => !l.StartsWith("key points", StringComparison.OrdinalIgnoreCase))
            .Select(l => l.Trim(':', ' '))
            .Where(l => !string.IsNullOrWhiteSpace(l))
            .ToList();

        var summary = string.Join(" ", summaryLines).Trim();
        if (summary.Length > 1200)
        {
            summary = summary[..1200] + "...";
        }

        return (summary, bullets);
    }

    private static string BuildFallbackDraft(AiDraftRequestDto request, string language)
    {
        if (language == "ar")
        {
            return
$@"نوع المستند: {request.DraftType}

الموضوع:
{request.Instructions}

الوقائع/السياق:
{(string.IsNullOrWhiteSpace(request.Context) ? "غير متوفر" : request.Context)}

المسودة:
1) تمهيد: يقدم هذا النص مسودة أولية قابلة للتطوير وفق مستندات القضية.
2) الوقائع: تُراجع الوقائع والمرفقات وتُصاغ بصيغة واضحة ومترابطة.
3) الأساس النظامي: يتم إسناد الطلب إلى النصوص والسابقة القضائية ذات الصلة.
4) الطلبات: تحديد الطلبات النهائية بوضوح، مع بدائل عند الحاجة.
5) المتابعة: التحقق من المواعيد والمرفقات وخطة التنفيذ قبل الاعتماد النهائي.";
        }

        return
$@"Document Type: {request.DraftType}

Subject:
{request.Instructions}

Facts/Context:
{(string.IsNullOrWhiteSpace(request.Context) ? "Not provided" : request.Context)}

Draft:
1) Introduction: This is an initial working draft to be refined with full case records.
2) Facts: Present material facts in chronological and verifiable form.
3) Legal Basis: Tie requests to applicable law and relevant precedent.
4) Requests: State clear primary requests and practical alternatives if needed.
5) Next Actions: Validate deadlines, exhibits, and execution owner before final issue.";
    }
}
