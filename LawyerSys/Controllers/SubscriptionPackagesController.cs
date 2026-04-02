using LawyerSys.DTOs;
using LawyerSys.Services.Subscriptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SubscriptionPackagesController : ControllerBase
{
    private readonly ISubscriptionPackagesService _subscriptionPackagesService;

    public SubscriptionPackagesController(ISubscriptionPackagesService subscriptionPackagesService)
    {
        _subscriptionPackagesService = subscriptionPackagesService;
    }

    [AllowAnonymous]
    [HttpGet("public")]
    public async Task<IActionResult> GetPublicPackages(CancellationToken cancellationToken)
    {
        var result = await _subscriptionPackagesService.GetPublicPackagesAsync(cancellationToken);
        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet]
    public async Task<IActionResult> GetPackages(CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var result = await _subscriptionPackagesService.GetPackagesAsync(cancellationToken);
        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{officeSize}")]
    public async Task<IActionResult> UpsertPackageGroup(string officeSize, [FromBody] SaveSubscriptionPackageGroupRequest request, CancellationToken cancellationToken)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        if (request.MonthlyPrice < 0 || request.AnnualPrice < 0)
        {
            return BadRequest(new { message = "Package prices must be greater than or equal to zero." });
        }

        var updated = await _subscriptionPackagesService.UpsertPackageGroupAsync(officeSize, request, cancellationToken);
        if (!updated)
        {
            return BadRequest(new { message = "Invalid office size." });
        }

        return Ok(new { message = "Package updated" });
    }
}
