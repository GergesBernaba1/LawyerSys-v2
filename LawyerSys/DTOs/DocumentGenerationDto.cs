namespace LawyerSys.DTOs;

public class GenerateDocumentRequestDto
{
    public string TemplateType { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }
    public Dictionary<string, string>? Variables { get; set; }
    public string Format { get; set; } = "txt";
}

public class DocumentTemplateDto
{
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}
