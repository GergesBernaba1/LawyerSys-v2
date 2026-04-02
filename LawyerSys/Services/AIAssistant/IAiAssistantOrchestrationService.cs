using LawyerSys.DTOs;

namespace LawyerSys.Services.AIAssistant;

public interface IAiAssistantOrchestrationService
{
    Task<AiSummaryResponseDto> SummarizeAsync(AiSummaryRequestDto request, CancellationToken cancellationToken = default);
    Task<AiDraftResponseDto> DraftAsync(AiDraftRequestDto request, CancellationToken cancellationToken = default);
    Task<AiTaskSuggestionsResponseDto> GetTaskDeadlineSuggestionsAsync(AiTaskSuggestionsQueryDto query, CancellationToken cancellationToken = default);
}
