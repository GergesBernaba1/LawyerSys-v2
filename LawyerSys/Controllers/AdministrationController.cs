using LawyerSys.DTOs;
using LawyerSys.Services.Administration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize(Policy = "AdminOnly")]
[ApiController]
[Route("api/[controller]")]
public class AdministrationController : ControllerBase
{
    private readonly IAdministrationService _administrationService;

    public AdministrationController(IAdministrationService administrationService)
    {
        _administrationService = administrationService;
    }

    [HttpGet("overview")]
    public async Task<ActionResult<AdministrationOverviewDto>> GetOverview(CancellationToken cancellationToken)
    {
        var result = await _administrationService.GetOverviewAsync(cancellationToken);
        return Ok(result);
    }
}
