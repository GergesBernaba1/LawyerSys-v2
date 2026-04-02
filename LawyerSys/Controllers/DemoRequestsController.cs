using LawyerSys.DTOs;
using LawyerSys.Services.Demo;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DemoRequestsController : ControllerBase
{
    private readonly IDemoRequestsService _demoRequestsService;
    private readonly UserManager<ApplicationUser> _userManager;

    public DemoRequestsController(
        IDemoRequestsService demoRequestsService,
        UserManager<ApplicationUser> userManager)
    {
        _demoRequestsService = demoRequestsService;
        _userManager = userManager;
    }

    [AllowAnonymous]
    [HttpPost]
    public async Task<IActionResult> CreateDemoRequest([FromBody] CreateDemoRequestRequest request, CancellationToken cancellationToken)
    {
        var result = await _demoRequestsService.CreateDemoRequestAsync(request, cancellationToken);
        if (!result.Success)
        {
            return BadRequest(new { message = result.Message });
        }

        return Ok(new { message = result.Message });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet]
    public async Task<IActionResult> GetDemoRequests(CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var items = await _demoRequestsService.GetDemoRequestsAsync(cancellationToken);
        return Ok(items);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id:int}/review")]
    public async Task<IActionResult> ReviewDemoRequest(int id, [FromBody] ReviewDemoRequestRequest request, CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var result = await _demoRequestsService.ReviewDemoRequestAsync(id, request, _userManager.GetUserId(User), cancellationToken);
        if (result.InvalidStatus)
        {
            return BadRequest(new { message = result.Message });
        }
        if (result.NotFound)
        {
            return NotFound(new { message = result.Message });
        }

        return Ok(new { message = result.Message });
    }
}
