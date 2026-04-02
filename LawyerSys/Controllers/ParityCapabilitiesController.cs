using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityRead)]
[ApiController]
[Route("api/parity/capabilities")]
public class ParityCapabilitiesController : ControllerBase
{
    private readonly IParityRoadmapService _service;

    public ParityCapabilitiesController(IParityRoadmapService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ParityCapabilityDto>>> GetCapabilities(CancellationToken cancellationToken)
    {
        return Ok(await _service.GetCapabilitiesAsync(cancellationToken));
    }
}
