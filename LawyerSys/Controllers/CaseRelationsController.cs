using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.CaseRelations;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/cases")]
public class CaseRelationsController : ControllerBase
{
    private readonly ICaseRelationsService _caseRelationsService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CaseRelationsController(
        ICaseRelationsService caseRelationsService,
        IStringLocalizer<SharedResource> localizer)
    {
        _caseRelationsService = caseRelationsService;
        _localizer = localizer;
    }

    // ========== CASE - CUSTOMER RELATIONS ==========

    [HttpGet("{caseCode}/customers")]
    public async Task<ActionResult> GetCaseCustomers(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseCustomersAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> AddCustomerToCase(int caseCode, int customerId)
    {
        var result = await _caseRelationsService.AddCustomerToCaseAsync(caseCode, customerId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "Customer", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> RemoveCustomerFromCase(int caseCode, int customerId)
    {
        var result = await _caseRelationsService.RemoveCustomerFromCaseAsync(caseCode, customerId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "Customer", "case"].Value });
    }

    // ========== CASE - CONTENDER RELATIONS ==========

    [HttpGet("{caseCode}/contenders")]
    public async Task<ActionResult> GetCaseContenders(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseContendersAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> AddContenderToCase(int caseCode, int contenderId)
    {
        var result = await _caseRelationsService.AddContenderToCaseAsync(caseCode, contenderId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "Contender", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> RemoveContenderFromCase(int caseCode, int contenderId)
    {
        var result = await _caseRelationsService.RemoveContenderFromCaseAsync(caseCode, contenderId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "Contender", "case"].Value });
    }

    // ========== CASE - COURT RELATIONS ==========

    [HttpGet("{caseCode}/courts")]
    public async Task<ActionResult> GetCaseCourts(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseCourtsAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> AddCourtToCase(int caseCode, int courtId)
    {
        var result = await _caseRelationsService.AddCourtToCaseAsync(caseCode, courtId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "Court", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> RemoveCourtFromCase(int caseCode, int courtId)
    {
        var result = await _caseRelationsService.RemoveCourtFromCaseAsync(caseCode, courtId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "Court", "case"].Value });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{caseCode}/courts/{oldCourtId}/change/{newCourtId}")]
    public async Task<ActionResult> ChangeCourtForCase(int caseCode, int oldCourtId, int newCourtId)
    {
        var result = await _caseRelationsService.ChangeCourtForCaseAsync(caseCode, oldCourtId, newCourtId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["Updated"].Value });
    }

    // ========== CASE - EMPLOYEE RELATIONS ==========

    [HttpGet("{caseCode}/employees")]
    public async Task<ActionResult> GetCaseEmployees(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseEmployeesAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> AddEmployeeToCase(int caseCode, int employeeId)
    {
        var result = await _caseRelationsService.AddEmployeeToCaseAsync(caseCode, employeeId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "Employee", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> RemoveEmployeeFromCase(int caseCode, int employeeId)
    {
        var result = await _caseRelationsService.RemoveEmployeeFromCaseAsync(caseCode, employeeId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "Employee", "case"].Value });
    }

    // ========== CASE - SITING RELATIONS ==========

    [HttpGet("{caseCode}/sitings")]
    public async Task<ActionResult> GetCaseSitings(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseSitingsAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> AddSitingToCase(int caseCode, int sitingId)
    {
        var result = await _caseRelationsService.AddSitingToCaseAsync(caseCode, sitingId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "Siting", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> RemoveSitingFromCase(int caseCode, int sitingId)
    {
        var result = await _caseRelationsService.RemoveSitingFromCaseAsync(caseCode, sitingId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "Siting", "case"].Value });
    }

    // ========== CASE - FILE RELATIONS ==========

    [HttpGet("{caseCode}/files")]
    public async Task<ActionResult> GetCaseFiles(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseFilesAsync(caseCode, HttpContext.RequestAborted));

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> AddFileToCase(int caseCode, int fileId)
    {
        var result = await _caseRelationsService.AddFileToCaseAsync(caseCode, fileId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["AddedTo", "File", "case"].Value, id = result.Payload });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> RemoveFileFromCase(int caseCode, int fileId)
    {
        var result = await _caseRelationsService.RemoveFileFromCaseAsync(caseCode, fileId, HttpContext.RequestAborted);
        if (!result.IsSuccess)
            return MapServiceResult(result);
        return Ok(new { message = _localizer["RemovedFrom", "File", "case"].Value });
    }

    // ========== FULL CASE DETAILS ==========

    [HttpGet("{caseCode}/full")]
    public async Task<ActionResult> GetCaseFullDetails(int caseCode)
        => MapServiceResult(await _caseRelationsService.GetCaseFullDetailsAsync(caseCode, HttpContext.RequestAborted));

    private ActionResult MapServiceResult<T>(ServiceResult<T> result)
    {
        if (result.IsSuccess)
            return Ok(result.Payload);

        var message = string.IsNullOrWhiteSpace(result.MessageKey) ? string.Empty : _localizer[result.MessageKey, result.MessageArguments].Value;
        return result.Status switch
        {
            ServiceResultStatus.Unauthorized => Unauthorized(new { message }),
            ServiceResultStatus.Forbidden => Forbid(),
            ServiceResultStatus.NotFound => NotFound(new { message }),
            ServiceResultStatus.ValidationFailed => BadRequest(new { message, errors = result.ValidationIssues }),
            ServiceResultStatus.Conflict => BadRequest(new { message }),
            ServiceResultStatus.BusinessRuleFailed => BadRequest(new { message }),
            _ => BadRequest(new { message })
        };
    }
}
