using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CourtsController : ControllerBase
{
    private readonly ICourtService _courtService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CourtsController(ICourtService courtService, IStringLocalizer<SharedResource> localizer)
    {
        _courtService = courtService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CourtDto>>> GetCourts([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _courtService.GetCourtsAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var courts = await _courtService.GetCourtsAsync(search);
        return Ok(courts);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CourtDto>> GetCourt(int id)
    {
        var court = await _courtService.GetCourtAsync(id);
        if (court == null)
            return this.EntityNotFound<CourtDto>(_localizer, "Court");

        return Ok(court);
    }

    [HttpGet("government-options")]
    public async Task<ActionResult<IEnumerable<GovernamentDto>>> GetGovernmentOptions()
    {
        var items = await _courtService.GetGovernmentOptionsAsync();
        return Ok(items);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<CourtDto>> CreateCourt([FromBody] CreateCourtDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _courtService.CreateCourtAsync(dto);
            return CreatedAtAction(nameof(GetCourt), new { id = created.Id }, created);
        }
        catch (InvalidOperationException)
        {
            return this.ApiResponseError<CourtDto>(_localizer, "SelectedCityOutsideProfileCountry");
        }
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCourt(int id, [FromBody] UpdateCourtDto dto)
    {
        try
        {
            var updated = await _courtService.UpdateCourtAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Court");
        }
        catch (InvalidOperationException)
        {
            return BadRequest(new { message = _localizer["SelectedCityOutsideProfileCountry"].Value });
        }
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCourt(int id)
    {
        var deleted = await _courtService.DeleteCourtAsync(id);
        if (!deleted)
            return this.EntityNotFound(_localizer, "Court");

        return Ok(new { message = _localizer["CourtDeleted"].Value });
    }
}
