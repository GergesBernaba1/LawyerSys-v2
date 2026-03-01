using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class CourtFormTemplateDto
{
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class CourtDeadlineRuleDto
{
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int OffsetDays { get; set; }
    public string Anchor { get; set; } = "TriggerDate";
}

public class CourtJurisdictionPackDto
{
    public string Key { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string JurisdictionCode { get; set; } = string.Empty;
    public IReadOnlyList<CourtFormTemplateDto> Forms { get; set; } = Array.Empty<CourtFormTemplateDto>();
    public IReadOnlyList<CourtDeadlineRuleDto> DeadlineRules { get; set; } = Array.Empty<CourtDeadlineRuleDto>();
    public IReadOnlyList<string> FilingChannels { get; set; } = Array.Empty<string>();
}

public class CalculateCourtDeadlinesRequestDto
{
    [Required]
    [MaxLength(64)]
    public string PackKey { get; set; } = string.Empty;

    public int? CaseCode { get; set; }

    [Required]
    public DateOnly TriggerDate { get; set; }

    public DateOnly? HearingDate { get; set; }

    [MaxLength(5)]
    public string? Language { get; set; } = "en";
}

public class CourtDeadlineItemDto
{
    public string RuleKey { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public DateOnly DueDate { get; set; }
    public string Priority { get; set; } = "Medium";
    public string Notes { get; set; } = string.Empty;
}

public class CalculateCourtDeadlinesResponseDto
{
    public string PackKey { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public DateOnly TriggerDate { get; set; }
    public DateOnly? HearingDate { get; set; }
    public IReadOnlyList<CourtDeadlineItemDto> Deadlines { get; set; } = Array.Empty<CourtDeadlineItemDto>();
}

public class GenerateCourtFormRequestDto
{
    [Required]
    [MaxLength(64)]
    public string PackKey { get; set; } = string.Empty;

    [Required]
    [MaxLength(64)]
    public string FormKey { get; set; } = string.Empty;

    public int? CaseCode { get; set; }
    public int? CustomerId { get; set; }

    [MaxLength(10)]
    public string Format { get; set; } = "txt";

    [MaxLength(5)]
    public string? Language { get; set; } = "en";

    public Dictionary<string, string>? Variables { get; set; }
}

public class SubmitCourtFilingRequestDto
{
    [Required]
    [MaxLength(64)]
    public string PackKey { get; set; } = string.Empty;

    [Required]
    [MaxLength(64)]
    public string FormKey { get; set; } = string.Empty;

    [MaxLength(64)]
    public string FilingChannel { get; set; } = string.Empty;

    public int? CaseCode { get; set; }
    public int? CourtId { get; set; }
    public DateOnly? DueDate { get; set; }

    [MaxLength(2048)]
    public string? Notes { get; set; }

    [MaxLength(5)]
    public string? Language { get; set; } = "en";
}

public class CourtFilingSubmissionDto
{
    public string SubmissionId { get; set; } = string.Empty;
    public string PackKey { get; set; } = string.Empty;
    public string FormKey { get; set; } = string.Empty;
    public string FilingChannel { get; set; } = string.Empty;
    public int? CaseCode { get; set; }
    public int? CourtId { get; set; }
    public DateOnly? DueDate { get; set; }
    public string Status { get; set; } = "Submitted";
    public string Message { get; set; } = string.Empty;
    public string ExternalReference { get; set; } = string.Empty;
    public DateTime SubmittedAt { get; set; }
    public DateTime? LastStatusAt { get; set; }
    public DateTime? NextCheckAt { get; set; }
    public string? Notes { get; set; }
}
