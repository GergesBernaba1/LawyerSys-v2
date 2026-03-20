using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class SitingsController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IEmployeeAccessService _employeeAccessService;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public SitingsController(
        LegacyDbContext context,
        IEmployeeAccessService employeeAccessService,
        IInAppNotificationService inAppNotificationService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _employeeAccessService = employeeAccessService;
        _inAppNotificationService = inAppNotificationService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SitingDto>>> GetSitings([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Siting> query = _context.Sitings.Include(st => st.Cases_Sitings);

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var assignedCaseCodes = await _employeeAccessService.GetAssignedCaseCodesAsync();
            query = assignedCaseCodes.Length == 0
                ? query.Where(_ => false)
                : query.Where(st => st.Cases_Sitings.Any(cs => assignedCaseCodes.Contains(cs.Case_Code)));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(st => st.Judge_Name.Contains(s) || st.Notes.Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(st => st.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<SitingDto> { Items = items.Select(MapToDto), TotalCount = total, Page = p, PageSize = ps });
        }

        var sitings = await query.OrderBy(st => st.Id).ToListAsync();
        return Ok(sitings.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SitingDto>> GetSiting(int id)
    {
        var siting = await _context.Sitings.Include(st => st.Cases_Sitings).FirstOrDefaultAsync(st => st.Id == id);
        if (siting == null)
            return this.EntityNotFound<SitingDto>(_localizer, "Siting");

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
            if (!await CanAccessAllCasesAsync(caseCodes))
                return Forbid();
        }

        return Ok(MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<SitingDto>> CreateSiting([FromBody] CreateSitingDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (dto.CaseCode.HasValue)
        {
            var caseExists = await _context.Cases.AnyAsync(c => c.Code == dto.CaseCode.Value);
            if (!caseExists)
                return BadRequest(new { message = _localizer["CaseNotFoundForSiting"].Value });
        }

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            if (!dto.CaseCode.HasValue)
                return BadRequest(new { message = _localizer["EmployeesMustLinkSiting"].Value });

            if (!await _employeeAccessService.CanAccessCaseAsync(dto.CaseCode.Value))
                return Forbid();
        }

        var siting = new Siting
        {
            Siting_Time = dto.SitingTime,
            Siting_Date = dto.SitingDate,
            Siting_Notification = dto.SitingNotification,
            Judge_Name = dto.JudgeName,
            Notes = dto.Notes ?? string.Empty
        };

        _context.Sitings.Add(siting);
        await _context.SaveChangesAsync();

        if (dto.CaseCode.HasValue)
        {
            var exists = await _context.Cases_Sitings.AnyAsync(cs => cs.Case_Code == dto.CaseCode.Value && cs.Siting_Id == siting.Id);
            if (!exists)
            {
                _context.Cases_Sitings.Add(new Cases_Siting { Case_Code = dto.CaseCode.Value, Siting_Id = siting.Id });
                await _context.SaveChangesAsync();
            }

            await _inAppNotificationService.NotifyCaseSitingScheduledAsync(dto.CaseCode.Value, siting.Id, siting.Siting_Time, siting.Judge_Name, HttpContext.RequestAborted);
        }

        await _context.Entry(siting).Collection(st => st.Cases_Sitings).LoadAsync();
        return CreatedAtAction(nameof(GetSiting), new { id = siting.Id }, MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateSiting(int id, [FromBody] UpdateSitingDto dto)
    {
        var siting = await _context.Sitings.Include(item => item.Cases_Sitings).FirstOrDefaultAsync(item => item.Id == id);
        if (siting == null)
            return this.EntityNotFound(_localizer, "Siting");

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
            if (!await CanAccessAllCasesAsync(caseCodes))
                return Forbid();
        }

        if (dto.SitingTime.HasValue) siting.Siting_Time = dto.SitingTime.Value;
        if (dto.SitingDate.HasValue) siting.Siting_Date = dto.SitingDate.Value;
        if (dto.SitingNotification.HasValue) siting.Siting_Notification = dto.SitingNotification.Value;
        if (dto.JudgeName != null) siting.Judge_Name = dto.JudgeName;
        if (dto.Notes != null) siting.Notes = dto.Notes;

        await _context.SaveChangesAsync();

        foreach (var caseCode in siting.Cases_Sitings.Select(item => item.Case_Code).Distinct())
            await _inAppNotificationService.NotifyCaseSitingUpdatedAsync(caseCode, siting.Id, siting.Siting_Time, siting.Judge_Name, HttpContext.RequestAborted);

        return Ok(MapToDto(siting));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSiting(int id)
    {
        var siting = await _context.Sitings.Include(item => item.Cases_Sitings).FirstOrDefaultAsync(item => item.Id == id);
        if (siting == null)
            return this.EntityNotFound(_localizer, "Siting");

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var caseCodesToValidate = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
            if (!await CanAccessAllCasesAsync(caseCodesToValidate))
                return Forbid();
        }

        var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToList();
        _context.Sitings.Remove(siting);
        await _context.SaveChangesAsync();

        foreach (var caseCode in caseCodes)
            await _inAppNotificationService.NotifyCaseSitingCancelledAsync(caseCode, id, HttpContext.RequestAborted);

        return Ok(new { message = _localizer["SitingDeleted"].Value });
    }

    private static SitingDto MapToDto(Siting s) => new()
    {
        Id = s.Id,
        CaseCode = s.Cases_Sitings.OrderBy(cs => cs.Id).Select(cs => (int?)cs.Case_Code).FirstOrDefault(),
        SitingTime = s.Siting_Time,
        SitingDate = s.Siting_Date,
        SitingNotification = s.Siting_Notification,
        JudgeName = s.Judge_Name,
        Notes = s.Notes
    };

    private async Task<bool> CanAccessAllCasesAsync(IEnumerable<int> caseCodes)
    {
        var distinct = caseCodes.Distinct().ToArray();
        if (distinct.Length == 0) return false;
        foreach (var code in distinct)
            if (!await _employeeAccessService.CanAccessCaseAsync(code)) return false;
        return true;
    }
}
