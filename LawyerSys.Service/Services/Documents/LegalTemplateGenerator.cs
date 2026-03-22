using LawyerSys.Services.Reporting;
using System.Globalization;
using System.Text;

namespace LawyerSys.Services.Documents;

public static class LegalTemplateGenerator
{
    private static readonly Dictionary<string, (string Name, string Description, string Body)> TemplatesEn = new(StringComparer.OrdinalIgnoreCase)
    {
        ["power-of-attorney"] = (
            "Power Of Attorney",
            "Generate a power of attorney draft with case and customer details.",
            "POWER OF ATTORNEY\n\nClient: {{CustomerName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nDate: {{Today}}\n\nI, {{CustomerName}}, hereby appoint {{LawyerName}} as my legal attorney to represent me in the above case.\n\nClient Signature: ____________________\n"
        ),
        ["contract"] = (
            "Legal Services Contract",
            "Generate a legal services contract draft.",
            "LEGAL SERVICES CONTRACT\n\nThis agreement is made on {{Today}} between {{LawFirmName}} and {{CustomerName}} regarding case {{CaseCode}} ({{CaseType}}).\n\nScope:\n{{Scope}}\n\nFee Agreement:\n{{FeeTerms}}\n\nClient Signature: ____________________\nLawyer Signature: ____________________\n"
        ),
        ["court-filing"] = (
            "Court Filing Draft",
            "Generate a court filing draft with case context.",
            "COURT FILING DRAFT\n\nTo: {{CourtName}}\nCase Code: {{CaseCode}}\nCase Type: {{CaseType}}\nFiled by: {{LawyerName}}\nDate: {{Today}}\n\nSubject:\n{{Subject}}\n\nStatement:\n{{Statement}}\n"
        )
    };

    private static readonly Dictionary<string, (string Name, string Description, string Body)> TemplatesAr = new(StringComparer.OrdinalIgnoreCase)
    {
        ["power-of-attorney"] = (
            "توكيل",
            "إنشاء مسودة توكيل مع تفاصيل القضية والعميل.",
            "توكيل\n\nالعميل: {{CustomerName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nالتاريخ: {{Today}}\n\nأنا، {{CustomerName}}، أقوم بتعيين {{LawyerName}} كمحامي قانوني لتمثيلني في القضية المذكورة أعلاه.\n\nتوقيع العميل: ____________________\n"
        ),
        ["contract"] = (
            "عقد الخدمات القانونية",
            "إنشاء مسودة عقد خدمات قانونية.",
            "عقد الخدمات القانونية\n\nتم إبرام هذا الاتفاق في {{Today}} بين {{LawFirmName}} و {{CustomerName}} بشأن القضية {{CaseCode}} ({{CaseType}}).\n\nالنطاق:\n{{Scope}}\n\nاتفاقية الأتعاب:\n{{FeeTerms}}\n\nتوقيع العميل: ____________________\nتوقيع المحامي: ____________________\n"
        ),
        ["court-filing"] = (
            "مسودة قيد المحكمة",
            "إنشاء مسودة قيد محكمة مع سياق القضية.",
            "مسودة قيد المحكمة\n\nإلى: {{CourtName}}\nرقم القضية: {{CaseCode}}\nنوع القضية: {{CaseType}}\nمقدم بواسطة: {{LawyerName}}\nالتاريخ: {{Today}}\n\nالموضوع:\n{{Subject}}\n\nالبيان:\n{{Statement}}\n"
        )
    };

    private static Dictionary<string, (string Name, string Description, string Body)> GetTemplates(string? culture)
    {
        var normalizedCulture = culture?.ToLowerInvariant() ?? "en";
        
        // Check for Arabic variants
        if (normalizedCulture.StartsWith("ar"))
        {
            return TemplatesAr;
        }
        
        return TemplatesEn;
    }

    public static IEnumerable<(string Key, string Name, string Description)> ListTemplates(string? culture = null)
    {
        var templates = GetTemplates(culture);
        return templates.Select(kv => (kv.Key, kv.Value.Name, kv.Value.Description));
    }

    public static bool Exists(string templateType)
    {
        // Check in both templates since we don't know the culture at this point
        return TemplatesEn.ContainsKey(templateType) || TemplatesAr.ContainsKey(templateType);
    }

    public static string Render(string templateType, IDictionary<string, string> variables, string? culture = null)
    {
        var templates = GetTemplates(culture);
        
        if (!templates.TryGetValue(templateType, out var templateData))
        {
            // Fallback to English if template not found
            templateData = TemplatesEn[templateType];
        }
        
        var template = templateData.Body;
        foreach (var kv in variables)
        {
            template = template.Replace($"{{{{{kv.Key}}}}}", kv.Value ?? string.Empty, StringComparison.OrdinalIgnoreCase);
        }

        return template;
    }

    public static byte[] BuildOutput(string content, string format)
    {
        if (string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase))
        {
            return ReportExportBuilder.BuildSimplePdf("Generated Legal Document", content.Split('\n'));
        }

        return Encoding.UTF8.GetBytes(content);
    }

    public static string GetContentType(string format)
        => string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase) ? "application/pdf" : "text/plain";

    public static string GetFileExtension(string format)
        => string.Equals(format, "pdf", StringComparison.OrdinalIgnoreCase) ? "pdf" : "txt";
}
