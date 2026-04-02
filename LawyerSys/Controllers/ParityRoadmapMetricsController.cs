using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityWrite)]
[ApiController]
[Route("api/parity/roadmap-items/{roadmapItemId}/metrics")]
public class ParityRoadmapMetricsController : ControllerBase
{
    private readonly ParityRoadmapService _service;

    public ParityRoadmapMetricsController(IParityRoadmapService service)
    {
        _service = (ParityRoadmapService)service;
    }

    [HttpPost]
    public async Task<IActionResult> RecordMetric(string roadmapItemId, CancellationToken cancellationToken)
    {
        await _service.RecordMetricAsync(roadmapItemId, cancellationToken);
        return Ok(new { roadmapItemId, message = "Metric recorded" });
    }
}
