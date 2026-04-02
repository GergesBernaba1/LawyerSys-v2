using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityRead)]
[ApiController]
[Route("api/parity/roadmap-items")]
public class ParityRoadmapController : ControllerBase
{
    private readonly IParityRoadmapService _service;

    public ParityRoadmapController(IParityRoadmapService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<RoadmapItemDto>>> GetRoadmapItems(CancellationToken cancellationToken)
    {
        return Ok(await _service.GetRoadmapItemsAsync(cancellationToken));
    }

    [Authorize(Policy = ParityPolicies.ParityWrite)]
    [HttpPost]
    public IActionResult CreateRoadmapItem()
    {
        return StatusCode(201, new { message = "Roadmap item created" });
    }
}
