using LawyerSys.Services.Reporting;
using System.Text;

namespace LawyerSys.Services.Documents;

public static class LegalTemplateGenerator
{
    private static readonly Dictionary<string, (string Name, string Description, string Body)> Templates = new(StringComparer.OrdinalIgnoreCase)
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

    public static IEnumerable<(string Key, string Name, string Description)> ListTemplates()
        => Templates.Select(kv => (kv.Key, kv.Value.Name, kv.Value.Description));

    public static bool Exists(string templateType) => Templates.ContainsKey(templateType);

    public static string Render(string templateType, IDictionary<string, string> variables)
    {
        var template = Templates[templateType].Body;
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
