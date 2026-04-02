using LawyerSys.DTOs;
using LawyerSys.Services.AIAssistant;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class AIAssistantController : ControllerBase
{
    private readonly IAiAssistantOrchestrationService _aiAssistantOrchestrationService;

    public AIAssistantController(IAiAssistantOrchestrationService aiAssistantOrchestrationService)
    {
        _aiAssistantOrchestrationService = aiAssistantOrchestrationService;
    }

    [HttpPost("summarize")]
    public async Task<ActionResult<AiSummaryResponseDto>> Summarize([FromBody] AiSummaryRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _aiAssistantOrchestrationService.SummarizeAsync(request, cancellationToken);
        return Ok(result);
    }

    [HttpPost("draft")]
    public async Task<ActionResult<AiDraftResponseDto>> Draft([FromBody] AiDraftRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _aiAssistantOrchestrationService.DraftAsync(request, cancellationToken);
        return Ok(result);
    }

    [HttpGet("task-deadline-suggestions")]
    public async Task<ActionResult<AiTaskSuggestionsResponseDto>> GetTaskDeadlineSuggestions([FromQuery] AiTaskSuggestionsQueryDto query, CancellationToken cancellationToken)
    {
        var result = await _aiAssistantOrchestrationService.GetTaskDeadlineSuggestionsAsync(query, cancellationToken);
        return Ok(result);
    }
}
