using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.Extensions.Authorization;
using LawyerSys.Services.Parity;

namespace LawyerSys.Controllers;

[Authorize(Policy = ParityPolicies.ParityWrite)]
[ApiController]
[Route("api/parity/refresh")]
public class ParityRefreshController : ControllerBase
{
    private readonly ParityWeeklyRefreshService _service;

    public ParityRefreshController(ParityWeeklyRefreshService service)
    {
        _service = service;
    }

    [HttpPost]
    public async Task<IActionResult> Refresh(CancellationToken cancellationToken)
    {
        await _service.RunAsync(cancellationToken);
        return Accepted(new { message = "Refresh accepted" });
    }
}
