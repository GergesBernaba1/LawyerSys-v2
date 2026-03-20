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
public class SitingsController : ControllerBase
{
    private readonly ISitingService _sitingService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public SitingsController(ISitingService sitingService, IStringLocalizer<SharedResource> localizer)
    {
        _sitingService = sitingService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SitingDto>>> GetSitings([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var paged = await _sitingService.GetSitingsAsync(page.Value, pageSize.Value, search);
            return Ok(paged);
        }

        var sitings = await _sitingService.GetSitingsAsync(search);
        return Ok(sitings);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SitingDto>> GetSiting(int id)
    {
        var siting = await _sitingService.GetSitingAsync(id);
        if (siting == null)
            return this.EntityNotFound<SitingDto>(_localizer, "Siting");

        return Ok(siting);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<SitingDto>> CreateSiting([FromBody] CreateSitingDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _sitingService.CreateSitingAsync(dto);
            return CreatedAtAction(nameof(GetSiting), new { id = created.Id }, created);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = _localizer[ex.Message].Value });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSiting(int id, [FromBody] UpdateSitingDto dto)
    {
        try
        {
            var updated = await _sitingService.UpdateSitingAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Siting");
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSiting(int id)
    {
        try
        {
            var deleted = await _sitingService.DeleteSitingAsync(id);
            if (!deleted)
                return this.EntityNotFound(_localizer, "Siting");

            return Ok(new { message = _localizer["SitingDeleted"].Value });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }
}
