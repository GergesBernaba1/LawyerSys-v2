using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.DTOs;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Governments;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class GovernmentsController : ControllerBase
{
    private readonly IGovernmentsService _governmentsService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public GovernmentsController(
        IGovernmentsService governmentsService,
        IStringLocalizer<SharedResource> localizer)
    {
        _governmentsService = governmentsService;
        _localizer = localizer;
    }

    [HttpGet("location-catalog")]
    public async Task<ActionResult<IEnumerable<LocationCatalogCountryDto>>> GetLocationCatalog([FromQuery] int? countryId = null)
    {
        return Ok(await _governmentsService.GetLocationCatalogAsync(countryId, HttpContext.RequestAborted));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("cities")]
    public async Task<ActionResult<LocationCatalogCityDto>> CreateCity([FromBody] UpdateLocationCityDto dto)
    {
        return MapServiceResult(await _governmentsService.CreateCityAsync(dto, HttpContext.RequestAborted));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("cities/{id}")]
    public async Task<IActionResult> UpdateCity(int id, [FromBody] UpdateLocationCityDto dto)
    {
        return MapServiceResult(await _governmentsService.UpdateCityAsync(id, dto, HttpContext.RequestAborted));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("cities/{id}")]
    public async Task<IActionResult> DeleteCity(int id)
    {
        var result = await _governmentsService.DeleteCityAsync(id, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);

        return Ok(new { message = _localizer["CityDeleted"].Value });
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<GovernamentDto>>> GetGovernments([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        return Ok(await _governmentsService.GetGovernmentsAsync(page, pageSize, search, HttpContext.RequestAborted));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<GovernamentDto>> GetGovernment(int id)
    {
        return MapServiceResult(await _governmentsService.GetGovernmentAsync(id, HttpContext.RequestAborted));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<GovernamentDto>> CreateGovernment([FromBody] CreateGovernamentDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);
        var result = await _governmentsService.CreateGovernmentAsync(dto, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);

        return CreatedAtAction(nameof(GetGovernment), new { id = result.Payload!.Id }, result.Payload);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateGovernment(int id, [FromBody] CreateGovernamentDto dto)
    {
        return MapServiceResult(await _governmentsService.UpdateGovernmentAsync(id, dto, HttpContext.RequestAborted));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteGovernment(int id)
    {
        var result = await _governmentsService.DeleteGovernmentAsync(id, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);

        return Ok(new { message = _localizer["GovernmentDeleted"].Value });
    }

    private ActionResult MapServiceResult<T>(ServiceResult<T> result)
    {
        if (result.IsSuccess)
            return Ok(result.Payload);

        var message = string.IsNullOrWhiteSpace(result.MessageKey) ? string.Empty : _localizer[result.MessageKey, result.MessageArguments].Value;
        return result.Status switch
        {
            ServiceResultStatus.ValidationFailed => BadRequest(new { message, errors = result.ValidationIssues }),
            ServiceResultStatus.Unauthorized => Unauthorized(new { message }),
            ServiceResultStatus.Forbidden => StatusCode(StatusCodes.Status403Forbidden, new { message }),
            ServiceResultStatus.NotFound => NotFound(new { message }),
            ServiceResultStatus.Conflict => BadRequest(new { message }),
            ServiceResultStatus.BusinessRuleFailed => BadRequest(new { message }),
            _ => BadRequest(new { message })
        };
    }
}
