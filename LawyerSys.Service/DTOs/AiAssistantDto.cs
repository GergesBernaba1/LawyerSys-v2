using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class AiSummaryRequestDto
{
    [Required]
    [MaxLength(20000)]
    public string Text { get; set; } = string.Empty;

    [MaxLength(5)]
    public string? Language { get; set; } = "en";

    [Range(1, 8)]
    public int MaxKeyPoints { get; set; } = 5;
}

public class AiSummaryResponseDto
{
    public string Language { get; set; } = "en";
    public string Summary { get; set; } = string.Empty;
    public IReadOnlyList<string> KeyPoints { get; set; } = Array.Empty<string>();
    public bool UsedAiModel { get; set; }
}

public class AiDraftRequestDto
{
    [Required]
    [MaxLength(64)]
    public string DraftType { get; set; } = "General";

    [Required]
    [MaxLength(8000)]
    public string Instructions { get; set; } = string.Empty;

    [MaxLength(20000)]
    public string? Context { get; set; }

    [MaxLength(5)]
    public string? Language { get; set; } = "en";
}

public class AiDraftResponseDto
{
    public string Language { get; set; } = "en";
    public string DraftType { get; set; } = "General";
    public string DraftText { get; set; } = string.Empty;
    public string Disclaimer { get; set; } = string.Empty;
    public bool UsedAiModel { get; set; }
}

public class AiTaskSuggestionsQueryDto
{
    [Range(3, 45)]
    public int Days { get; set; } = 14;

    [Range(3, 20)]
    public int MaxSuggestions { get; set; } = 12;

    [MaxLength(5)]
    public string? Language { get; set; } = "en";
}

public class AiTaskSuggestionItemDto
{
    public string Title { get; set; } = string.Empty;
    public DateOnly SuggestedDueDate { get; set; }
    public DateTime SuggestedReminderAt { get; set; }
    public string Priority { get; set; } = "Medium";
    public string Rationale { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty;
    public int? SourceId { get; set; }
    public int? CaseCode { get; set; }
}

public class AiTaskSuggestionsResponseDto
{
    public string Language { get; set; } = "en";
    public DateOnly GeneratedForDate { get; set; }
    public int DaysWindow { get; set; }
    public IReadOnlyList<AiTaskSuggestionItemDto> Suggestions { get; set; } = Array.Empty<AiTaskSuggestionItemDto>();
    public bool UsedAiModel { get; set; }
}
