using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services.Contenders;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ContendersController : ControllerBase
{
    private readonly IContendersService _contendersService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public ContendersController(IContendersService contendersService, IStringLocalizer<SharedResource> localizer)
    {
        _contendersService = contendersService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ContenderDto>>> GetContenders([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null, CancellationToken cancellationToken = default)
    {
        var result = await _contendersService.GetContendersAsync(page, pageSize, search, cancellationToken);

        if (result.Page.HasValue && result.PageSize.HasValue && result.TotalCount.HasValue)
        {
            return Ok(new PagedResult<ContenderDto>
            {
                Items = result.Items,
                TotalCount = result.TotalCount.Value,
                Page = result.Page.Value,
                PageSize = result.PageSize.Value
            });
        }

        return Ok(result.Items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ContenderDto>> GetContender(int id, CancellationToken cancellationToken)
    {
        var contender = await _contendersService.GetContenderAsync(id, cancellationToken);
        if (contender == null)
        {
            return this.EntityNotFound<ContenderDto>(_localizer, "Contender");
        }

        return Ok(contender);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<ContenderDto>> CreateContender([FromBody] CreateContenderDto dto, CancellationToken cancellationToken)
    {
        var contender = await _contendersService.CreateContenderAsync(dto, cancellationToken);
        return CreatedAtAction(nameof(GetContender), new { id = contender.Id }, contender);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateContender(int id, [FromBody] UpdateContenderDto dto, CancellationToken cancellationToken)
    {
        var contender = await _contendersService.UpdateContenderAsync(id, dto, cancellationToken);
        if (contender == null)
        {
            return this.EntityNotFound(_localizer, "Contender");
        }

        return Ok(contender);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteContender(int id, CancellationToken cancellationToken)
    {
        var deleted = await _contendersService.DeleteContenderAsync(id, cancellationToken);
        if (!deleted)
        {
            return this.EntityNotFound(_localizer, "Contender");
        }

        return Ok(new { message = _localizer["ContenderDeleted"].Value });
    }
}
