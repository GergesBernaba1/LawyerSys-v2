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
public class CasesController : ControllerBase
{
    private readonly ICaseService _caseService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CasesController(ICaseService caseService, IStringLocalizer<SharedResource> localizer)
    {
        _caseService = caseService;
        _localizer = localizer;
    }

    // GET: api/cases
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CaseDto>>> GetCases([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _caseService.GetCasesAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var cases = await _caseService.GetCasesAsync(search);
        return Ok(cases);
    }

    // GET: api/cases/{code}
    [HttpGet("{code}")]
    public async Task<ActionResult<CaseDto>> GetCase(int code)
    {
        var caseDto = await _caseService.GetCaseAsync(code);
        if (caseDto == null)
            return this.EntityNotFound<CaseDto>(_localizer, "Case");

        // Check access
        if (!await _caseService.CanAccessCaseAsync(code))
            return Forbid();

        return Ok(caseDto);
    }

    // POST: api/cases
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<CaseDto>> CreateCase([FromBody] CreateCaseDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _caseService.CreateCaseAsync(dto);
            return CreatedAtAction(nameof(GetCase), new { code = created.Code }, created);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // PUT: api/cases/{code}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{code}")]
    public async Task<IActionResult> UpdateCase(int code, [FromBody] UpdateCaseDto dto)
    {
        // Check access
        if (!await _caseService.CanModifyCaseAsync(code))
            return Forbid();

        try
        {
            var updated = await _caseService.UpdateCaseAsync(code, dto);
            return Ok(updated);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Case");
        }
    }

    // DELETE: api/cases/{code}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{code}")]
    public async Task<IActionResult> DeleteCase(int code)
    {
        // Check access
        if (!await _caseService.CanModifyCaseAsync(code))
            return Forbid();

        var deleted = await _caseService.DeleteCaseAsync(code);
        if (!deleted)
            return this.EntityNotFound(_localizer, "Case");

        return Ok(new { message = _localizer["CaseDeleted"].Value });
    }

    // POST: api/cases/{code}/assign-employee
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{code}/assign-employee")]
    public async Task<IActionResult> AssignEmployee(int code, [FromBody] AssignEmployeeDto dto)
    {
        try
        {
            await _caseService.AssignEmployeeAsync(code, dto.EmployeeId);
            return Ok(new { message = _localizer["EmployeeAssigned"].Value });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // DELETE: api/cases/{code}/assign-employee
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{code}/assign-employee")]
    public async Task<IActionResult> UnassignEmployee(int code)
    {
        try
        {
            await _caseService.UnassignEmployeeAsync(code);
            return Ok(new { message = _localizer["AssignmentRemoved"].Value });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // GET: api/cases/assignments
    [HttpGet("assignments")]
    public async Task<ActionResult<IEnumerable<object>>> GetAssignments()
    {
        var assignments = await _caseService.GetAssignmentsAsync();
        return Ok(assignments);
    }

    // POST: api/cases/{code}/status
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{code}/status")]
    public async Task<IActionResult> ChangeCaseStatus(int code, [FromBody] ChangeCaseStatusDto dto)
    {
        // Permission check: employees can only modify their assigned cases
        if (!await _caseService.CanModifyCaseAsync(code))
            return Forbid();

        try
        {
            var updated = await _caseService.ChangeCaseStatusAsync(code, dto.Status);
            return Ok(updated);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // GET: api/cases/status-options
    [HttpGet("status-options")]
    public async Task<ActionResult<IEnumerable<object>>> GetStatusOptions()
    {
        var options = await _caseService.GetStatusOptionsAsync();
        return Ok(options);
    }

    // GET: api/cases/{code}/status-history
    [HttpGet("{code}/status-history")]
    public async Task<ActionResult<IEnumerable<CaseStatusHistoryDto>>> GetStatusHistory(int code)
    {
        try
        {
            var history = await _caseService.GetStatusHistoryAsync(code);
            return Ok(history);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Case");
        }
    }

    // GET: api/cases/{code}/court-history
    [HttpGet("{code}/court-history")]
    public async Task<ActionResult<IEnumerable<CaseCourtHistoryDto>>> GetCourtHistory(int code)
    {
        try
        {
            var history = await _caseService.GetCourtHistoryAsync(code);
            return Ok(history);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Case");
        }
    }

    // GET: api/cases/{code}/timeline
    [HttpGet("{code}/timeline")]
    public async Task<ActionResult<CaseTimelineDto>> GetCaseTimeline(int code)
    {
        if (!await _caseService.CanAccessCaseAsync(code))
            return Forbid();

        try
        {
            var timeline = await _caseService.GetCaseTimelineAsync(code);
            return Ok(timeline);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Case");
        }
    }
}
