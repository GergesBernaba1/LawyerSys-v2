using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

public sealed record ParityStateTransitionRequest(string TargetState);

[Authorize(Policy = ParityPolicies.ParityWrite)]
[ApiController]
[Route("api/parity/roadmap-items/{roadmapItemId}/state")]
public class ParityRoadmapStateController : ControllerBase
{
    private readonly ParityRoadmapService _service;

    public ParityRoadmapStateController(IParityRoadmapService service)
    {
        _service = (ParityRoadmapService)service;
    }

    [HttpPatch]
    public async Task<IActionResult> TransitionState(string roadmapItemId, [FromBody] ParityStateTransitionRequest request, CancellationToken cancellationToken)
    {
        var allowed = await _service.TryTransitionStateAsync(roadmapItemId, request.TargetState, cancellationToken);
        if (!allowed)
        {
            return UnprocessableEntity(new { message = "Completion requires KPI validation." });
        }

        return Ok(new { roadmapItemId, targetState = request.TargetState });
    }
}
