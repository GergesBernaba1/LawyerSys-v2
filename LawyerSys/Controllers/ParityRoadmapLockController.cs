using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityWrite)]
[ApiController]
[Route("api/parity/roadmap-items/{roadmapItemId}/lock")]
public class ParityRoadmapLockController : ControllerBase
{
    private readonly ParityRoadmapService _service;

    public ParityRoadmapLockController(IParityRoadmapService service)
    {
        _service = (ParityRoadmapService)service;
    }

    [HttpPost]
    public async Task<IActionResult> AcquireLock(string roadmapItemId, CancellationToken cancellationToken)
    {
        var acquired = await _service.TryAcquireLockAsync(roadmapItemId, User?.Identity?.Name ?? "unknown", cancellationToken);
        if (!acquired)
        {
            return Conflict(new { message = "Lock already acquired." });
        }

        return Ok(new { roadmapItemId, message = "Lock acquired" });
    }
}
