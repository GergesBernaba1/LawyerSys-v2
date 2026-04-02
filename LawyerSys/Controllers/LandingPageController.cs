using LawyerSys.DTOs;
using LawyerSys.Services.Landing;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LandingPageController : ControllerBase
{
    private readonly ILandingPageService _landingPageService;

    public LandingPageController(ILandingPageService landingPageService)
    {
        _landingPageService = landingPageService;
    }

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<LandingPagePublicDto>> GetLandingPage(CancellationToken cancellationToken)
    {
        var result = await _landingPageService.GetLandingPageAsync(cancellationToken);
        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin")]
    public async Task<ActionResult<LandingPageAdminDto>> GetLandingPageAdmin(CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var result = await _landingPageService.GetLandingPageAdminAsync(cancellationToken);
        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut]
    public async Task<ActionResult<LandingPageAdminDto>> UpdateLandingPage([FromBody] UpdateLandingPageRequest request, CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var result = await _landingPageService.UpdateLandingPageAsync(request, cancellationToken);
        return Ok(result);
    }
}
