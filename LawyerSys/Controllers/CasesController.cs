using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CasesController : ControllerBase
{
    private static readonly Dictionary<DTOs.CaseStatus, DTOs.CaseStatus[]> AllowedStatusTransitions = new()
    {
        [DTOs.CaseStatus.New] = new[] { DTOs.CaseStatus.InProgress, DTOs.CaseStatus.AwaitingHearing, DTOs.CaseStatus.Closed },
        [DTOs.CaseStatus.InProgress] = new[] { DTOs.CaseStatus.AwaitingHearing, DTOs.CaseStatus.Closed, DTOs.CaseStatus.Won, DTOs.CaseStatus.Lost },
        [DTOs.CaseStatus.AwaitingHearing] = new[] { DTOs.CaseStatus.InProgress, DTOs.CaseStatus.Closed, DTOs.CaseStatus.Won, DTOs.CaseStatus.Lost },
        [DTOs.CaseStatus.Closed] = new[] { DTOs.CaseStatus.Won, DTOs.CaseStatus.Lost, DTOs.CaseStatus.InProgress },
        [DTOs.CaseStatus.Won] = Array.Empty<DTOs.CaseStatus>(),
        [DTOs.CaseStatus.Lost] = Array.Empty<DTOs.CaseStatus>()
    };

    private readonly LegacyDbContext _context;
    private readonly IUserContext _userContext;

    public CasesController(LegacyDbContext context, IUserContext userContext)
    {
        _context = context;
        _userContext = userContext;
    }

    // GET: api/cases
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CaseDto>>> GetCases([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        var roles = await _userContext.GetUserRolesAsync();
        var isAdmin = roles.Contains("Admin");
        var isEmployee = roles.Contains("Employee");
        var isCustomer = roles.Contains("Customer");

        IQueryable<Case> query = _context.Cases;

        if (isCustomer && !isAdmin && !isEmployee)
        {
            // Customer: Only see cases they are linked to
            var customer = await _context.Customers
                .Include(c => c.Users)
                .FirstOrDefaultAsync(c => c.Users != null && c.Users.User_Name == _userContext.GetUserName());

            if (customer == null)
                return Ok(Array.Empty<CaseDto>());

            var caseCodes = await _context.Custmors_Cases
                .Where(cc => cc.Custmors_Id == customer.Id)
                .Select(cc => cc.Case_Id)
                .ToListAsync();

            query = query.Where(c => caseCodes.Contains(c.Code));
        }
        else if (isEmployee && !isAdmin)
        {
            // Employee: Only see assigned cases
            var employee = await _context.Employees
                .Include(e => e.Users)
                .FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == _userContext.GetUserName());

            if (employee == null)
                return Ok(Array.Empty<CaseDto>());

            var caseCodes = await _context.Cases_Employees
                .Where(ce => ce.Employee_Id == employee.id)
                .Select(ce => ce.Case_Code)
                .ToListAsync();

            query = query.Where(c => caseCodes.Contains(c.Code));
        }
        // Admin sees all cases

        // Apply search (optional)
        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c => c.Code.ToString().Contains(s) || c.Invition_Type.Contains(s) || c.Notes.Contains(s));
        }

        // If pagination params are provided, return paged result; otherwise keep backward-compatible behavior
        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Code).Skip((p - 1) * ps).Take(ps).ToListAsync();

            var dtoItems = items.Select(MapToDto);
            var paged = new PagedResult<CaseDto>
            {
                Items = dtoItems,
                TotalCount = total,
                Page = p,
                PageSize = ps
            };
            return Ok(paged);
        }

        var cases = await query.OrderBy(c => c.Code).ToListAsync();
        return Ok(cases.Select(MapToDto));
    }

    // GET: api/cases/{code}
    [HttpGet("{code}")]
    public async Task<ActionResult<CaseDto>> GetCase(int code)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        // Check access
        if (!await CanAccessCase(code))
            return Forbid();

        return Ok(MapToDto(caseEntity));
    }

    // POST: api/cases
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<CaseDto>> CreateCase([FromBody] CreateCaseDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if Code already exists
        if (await _context.Cases.AnyAsync(c => c.Code == dto.Code))
            return BadRequest(new { message = "A case with this code already exists" });

        var caseEntity = new Case
        {
            Code = dto.Code,
            Invitions_Statment = dto.InvitionsStatment,
            Invition_Type = dto.InvitionType,
            Invition_Date = dto.InvitionDate,
            Total_Amount = dto.TotalAmount,
            Notes = dto.Notes ?? string.Empty,
            Status = (int)DTOs.CaseStatus.New
        };

        _context.Cases.Add(caseEntity);
        _context.CaseStatusHistories.Add(new CaseStatusHistory
        {
            Case_Id = caseEntity.Code,
            OldStatus = (int)DTOs.CaseStatus.New,
            NewStatus = (int)DTOs.CaseStatus.New,
            ChangedBy = _userContext.GetUserName() ?? "System",
            ChangedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCase), new { code = caseEntity.Code }, MapToDto(caseEntity));
    }

    // PUT: api/cases/{code}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{code}")]
    public async Task<IActionResult> UpdateCase(int code, [FromBody] UpdateCaseDto dto)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        // Employees can only update their assigned cases
        if (!await CanModifyCase(code))
            return Forbid();

        if (dto.InvitionsStatment != null) caseEntity.Invitions_Statment = dto.InvitionsStatment;
        if (dto.InvitionType != null) caseEntity.Invition_Type = dto.InvitionType;
        if (dto.InvitionDate.HasValue) caseEntity.Invition_Date = dto.InvitionDate.Value;
        if (dto.TotalAmount.HasValue) caseEntity.Total_Amount = dto.TotalAmount.Value;
        if (dto.Notes != null) caseEntity.Notes = dto.Notes;

        await _context.SaveChangesAsync();

        return Ok(MapToDto(caseEntity));
    }

    // DELETE: api/cases/{code}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{code}")]
    public async Task<IActionResult> DeleteCase(int code)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        // Employees can only delete their assigned cases
        if (!await CanModifyCase(code))
            return Forbid();

        _context.Cases.Remove(caseEntity);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Case deleted" });
    }

    // POST: api/cases/{code}/assign-employee
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{code}/assign-employee")]
    public async Task<IActionResult> AssignEmployee(int code, [FromBody] AssignEmployeeDto dto)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
        if (caseEntity == null) return NotFound(new { message = "Case not found" });

        var employee = await _context.Employees.FindAsync(dto.EmployeeId);
        if (employee == null) return NotFound(new { message = "Employee not found" });

        // Remove existing assignments for this case to ensure single employee assignment
        var existing = _context.Cases_Employees.Where(ce => ce.Case_Code == code);
        _context.Cases_Employees.RemoveRange(existing);

        var assign = new Cases_Employee { Case_Code = code, Employee_Id = employee.id };
        _context.Cases_Employees.Add(assign);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee assigned" });
    }

    // DELETE: api/cases/{code}/assign-employee
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{code}/assign-employee")]
    public async Task<IActionResult> UnassignEmployee(int code)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
        if (caseEntity == null) return NotFound(new { message = "Case not found" });

        var existing = _context.Cases_Employees.Where(ce => ce.Case_Code == code);
        _context.Cases_Employees.RemoveRange(existing);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Assignment removed" });
    }

    // GET: api/cases/assignments
    [HttpGet("assignments")]
    public async Task<ActionResult<IEnumerable<object>>> GetAssignments()
    {
        var assignments = await _context.Cases_Employees
            .Include(ce => ce.Employee)
                .ThenInclude(e => e.Users)
            .Select(ce => new
            {
                caseCode = ce.Case_Code,
                employeeId = ce.Employee_Id,
                employee = ce.Employee != null && ce.Employee.Users != null ? new
                {
                    id = ce.Employee.Users.Id,
                    fullName = ce.Employee.Users.Full_Name,
                    userName = ce.Employee.Users.User_Name
                } : null
            })
            .ToListAsync();

        return Ok(assignments);
    }

    // POST: api/cases/{code}/status
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{code}/status")]
    public async Task<IActionResult> ChangeCaseStatus(int code, [FromBody] DTOs.ChangeCaseStatusDto dto)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
        if (caseEntity == null) return NotFound(new { message = "Case not found" });

        // permission check: employees can only modify their assigned cases
        if (!await CanModifyCase(code))
            return Forbid();

        if (string.IsNullOrWhiteSpace(dto.Status))
            return BadRequest(new { message = "Status is required" });

        if (!System.Enum.TryParse<DTOs.CaseStatus>(dto.Status, true, out var newStatus))
            return BadRequest(new { message = "Invalid status value" });

        var oldStatus = (DTOs.CaseStatus)caseEntity.Status;
        if (oldStatus == newStatus)
            return BadRequest(new { message = "Case already in requested status" });

        var allowedTargets = AllowedStatusTransitions.GetValueOrDefault(oldStatus, Array.Empty<DTOs.CaseStatus>());
        if (!allowedTargets.Contains(newStatus))
        {
            var allowed = string.Join(", ", allowedTargets.Select(MapStatusLabel));
            return BadRequest(new { message = $"Invalid status transition from {MapStatusLabel(oldStatus)} to {MapStatusLabel(newStatus)}. Allowed: {allowed}" });
        }

        caseEntity.Status = (int)newStatus;

        var history = new CaseStatusHistory
        {
            Case_Id = caseEntity.Code,
            OldStatus = (int)oldStatus,
            NewStatus = (int)newStatus,
            ChangedBy = _userContext.GetUserName(),
            ChangedAt = DateTime.UtcNow
        };

        _context.CaseStatusHistories.Add(history);
        await _context.SaveChangesAsync();

        return Ok(MapToDto(caseEntity));
    }

    // GET: api/cases/status-options
    [HttpGet("status-options")]
    public ActionResult<IEnumerable<object>> GetStatusOptions()
    {
        var options = Enum.GetValues<DTOs.CaseStatus>()
            .Select(s => new
            {
                value = (int)s,
                key = s.ToString(),
                label = MapStatusLabel(s),
                next = AllowedStatusTransitions.GetValueOrDefault(s, Array.Empty<DTOs.CaseStatus>())
                    .Select(n => new { value = (int)n, key = n.ToString(), label = MapStatusLabel(n) })
            });

        return Ok(options);
    }

    // GET: api/cases/{code}/status-history
    [HttpGet("{code}/status-history")]
    public async Task<ActionResult<IEnumerable<DTOs.CaseStatusHistoryDto>>> GetStatusHistory(int code)
    {
        var exists = await _context.Cases.AnyAsync(c => c.Code == code);
        if (!exists) return NotFound(new { message = "Case not found" });

        var list = await _context.CaseStatusHistories
            .Where(h => h.Case_Id == code)
            .OrderByDescending(h => h.ChangedAt)
            .Select(h => new DTOs.CaseStatusHistoryDto { Id = h.Id, CaseId = h.Case_Id, OldStatus = (DTOs.CaseStatus)h.OldStatus, NewStatus = (DTOs.CaseStatus)h.NewStatus, ChangedBy = h.ChangedBy, ChangedAt = h.ChangedAt })
            .ToListAsync();

        return Ok(list);
    }

    // GET: api/cases/{code}/timeline
    [HttpGet("{code}/timeline")]
    public async Task<ActionResult<DTOs.CaseTimelineDto>> GetCaseTimeline(int code)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        if (!await CanAccessCase(code))
            return Forbid();

        var events = new List<DTOs.CaseTimelineEventDto>
        {
            new()
            {
                Category = "Case",
                OccurredAt = caseEntity.Invition_Date.ToDateTime(TimeOnly.MinValue),
                Title = "Case opened",
                Description = $"Case type: {caseEntity.Invition_Type}"
            }
        };

        var hearings = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Case_Code == code)
            .Select(cs => new
            {
                cs.Siting_Id,
                cs.Siting.Siting_Time,
                cs.Siting.Judge_Name,
                cs.Siting.Notes
            })
            .ToListAsync();

        events.AddRange(hearings.Select(h => new DTOs.CaseTimelineEventDto
        {
            Category = "Hearing",
            OccurredAt = h.Siting_Time,
            Title = "Hearing scheduled",
            Description = $"Judge: {h.Judge_Name}. {h.Notes}",
            EntityId = h.Siting_Id
        }));

        var customerIds = await _context.Custmors_Cases
            .Where(cc => cc.Case_Id == code)
            .Select(cc => cc.Custmors_Id)
            .Distinct()
            .ToListAsync();

        var documents = await _context.Judicial_Documents
            .Where(d => customerIds.Contains(d.Customers_Id))
            .Select(d => new
            {
                d.Id,
                d.Doc_Type,
                d.Doc_Details
            })
            .ToListAsync();

        events.AddRange(documents.Select(d => new DTOs.CaseTimelineEventDto
        {
            Category = "Document",
            OccurredAt = DateTime.UtcNow,
            Title = "Judicial document attached",
            Description = $"{d.Doc_Type}: {d.Doc_Details}",
            EntityId = d.Id
        }));

        var statusChanges = await _context.CaseStatusHistories
            .Where(h => h.Case_Id == code)
            .OrderBy(h => h.ChangedAt)
            .ToListAsync();

        events.AddRange(statusChanges.Select(s => new DTOs.CaseTimelineEventDto
        {
            Category = "Status",
            OccurredAt = s.ChangedAt,
            Title = "Case status changed",
            Description = $"{MapStatusLabel((DTOs.CaseStatus)s.OldStatus)} -> {MapStatusLabel((DTOs.CaseStatus)s.NewStatus)} (by {s.ChangedBy ?? "Unknown"})",
            EntityId = s.Id
        }));

        var billingEvents = await _context.Billing_Pays
            .Where(p => customerIds.Contains(p.Custmor_Id))
            .OrderBy(p => p.Date_Of_Opreation)
            .Select(p => new
            {
                p.Id,
                p.Date_Of_Opreation,
                p.Amount,
                p.Notes
            })
            .ToListAsync();

        events.AddRange(billingEvents.Select(b => new DTOs.CaseTimelineEventDto
        {
            Category = "Billing",
            OccurredAt = b.Date_Of_Opreation.ToDateTime(TimeOnly.MinValue),
            Title = "Payment recorded",
            Description = $"Amount: {b.Amount:F2}. {b.Notes}",
            EntityId = b.Id
        }));

        return Ok(new DTOs.CaseTimelineDto
        {
            CaseCode = caseEntity.Code,
            CaseType = caseEntity.Invition_Type,
            Events = events.OrderBy(e => e.OccurredAt).ToList()
        });
    }

    private async Task<bool> CanAccessCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin"))
            return true;

        var userName = _userContext.GetUserName();

        if (roles.Contains("Employee"))
        {
            var employee = await _context.Employees
                .Include(e => e.Users)
                .FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == userName);

            if (employee == null) return false;

            return await _context.Cases_Employees
                .AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employee.id);
        }

        if (roles.Contains("Customer"))
        {
            var customer = await _context.Customers
                .Include(c => c.Users)
                .FirstOrDefaultAsync(c => c.Users != null && c.Users.User_Name == userName);

            if (customer == null) return false;

            return await _context.Custmors_Cases
                .AnyAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customer.Id);
        }

        return false;
    }

    private async Task<bool> CanModifyCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin"))
            return true;

        if (roles.Contains("Employee"))
        {
            var userName = _userContext.GetUserName();
            var employee = await _context.Employees
                .Include(e => e.Users)
                .FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == userName);

            if (employee == null) return false;

            return await _context.Cases_Employees
                .AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employee.id);
        }

        // Customers cannot modify cases
        return false;
    }

    private static CaseDto MapToDto(Case c) => new()
    {
        Id = c.Id,
        Code = c.Code,
        InvitionsStatment = c.Invitions_Statment,
        InvitionType = c.Invition_Type,
        InvitionDate = c.Invition_Date,
        TotalAmount = c.Total_Amount,
        Notes = c.Notes,
        Status = (DTOs.CaseStatus)c.Status
    };

    private static string MapStatusLabel(DTOs.CaseStatus status) => status switch
    {
        DTOs.CaseStatus.New => "New",
        DTOs.CaseStatus.InProgress => "In Progress",
        DTOs.CaseStatus.AwaitingHearing => "Awaiting Hearing",
        DTOs.CaseStatus.Closed => "Closed",
        DTOs.CaseStatus.Won => "Won",
        DTOs.CaseStatus.Lost => "Lost",
        _ => "Unknown"
    };
}
