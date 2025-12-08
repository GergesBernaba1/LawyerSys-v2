using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;

[ApiController]
[Route("/health")]
public class HealthController : ControllerBase
{
    private readonly IStringLocalizer<SharedResource> _localizer;

    public HealthController(IStringLocalizer<SharedResource> localizer)
    {
        _localizer = localizer;
    }

    [HttpGet]
    public IActionResult Get() => Ok(new { status = _localizer["Healthy"]?.Value ?? "healthy" });
}
