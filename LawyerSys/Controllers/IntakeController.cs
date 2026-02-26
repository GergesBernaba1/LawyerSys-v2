using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class IntakeController : ControllerBase
{
    private readonly LegacyDbContext _legacy;
    private readonly ApplicationDbContext _appDb;

    public IntakeController(LegacyDbContext legacy, ApplicationDbContext appDb)
    {
        _legacy = legacy;
        _appDb = appDb;
    }

    [AllowAnonymous]
    [HttpPost("public")]
    public async Task<ActionResult<IntakeLeadDto>> CreatePublicLead([FromBody] CreatePublicIntakeLeadDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var lead = new IntakeLead
        {
            FullName = dto.FullName.Trim(),
            Email = string.IsNullOrWhiteSpace(dto.Email) ? null : dto.Email.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(dto.PhoneNumber) ? null : dto.PhoneNumber.Trim(),
            NationalId = string.IsNullOrWhiteSpace(dto.NationalId) ? null : dto.NationalId.Trim(),
            Subject = dto.Subject.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            DesiredCaseType = string.IsNullOrWhiteSpace(dto.DesiredCaseType) ? null : dto.DesiredCaseType.Trim(),
            Status = "New",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _legacy.IntakeLeads.Add(lead);
        await _legacy.SaveChangesAsync();

        return CreatedAtAction(nameof(GetLeadById), new { id = lead.Id }, MapLead(lead));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpGet]
    public async Task<ActionResult<IEnumerable<IntakeLeadDto>>> GetLeads([FromQuery] string? status = null, [FromQuery] string? search = null, [FromQuery] int? assignedEmployeeId = null)
    {
        IQueryable<IntakeLead> query = _legacy.IntakeLeads.OrderByDescending(x => x.CreatedAt);

        if (!string.IsNullOrWhiteSpace(status))
        {
            var s = status.Trim();
            query = query.Where(x => x.Status == s);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(x =>
                x.FullName.Contains(s) ||
                (x.Email != null && x.Email.Contains(s)) ||
                (x.PhoneNumber != null && x.PhoneNumber.Contains(s)) ||
                x.Subject.Contains(s));
        }

        if (assignedEmployeeId.HasValue)
        {
            query = query.Where(x => x.AssignedEmployeeId == assignedEmployeeId.Value);
        }

        var items = await query.ToListAsync();
        return Ok(items.Select(MapLead));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpGet("assignment-options")]
    public async Task<ActionResult<IEnumerable<IntakeAssignmentOptionDto>>> GetAssignmentOptions()
    {
        var employees = await _legacy.Employees
            .Include(e => e.Users)
            .OrderBy(e => e.Users.Full_Name)
            .Select(e => new IntakeAssignmentOptionDto
            {
                EmployeeId = e.id,
                Name = string.IsNullOrWhiteSpace(e.Users.Full_Name)
                    ? $"Employee #{e.id}"
                    : e.Users.Full_Name
            })
            .ToListAsync();

        return Ok(employees);
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpGet("{id}")]
    public async Task<ActionResult<IntakeLeadDto>> GetLeadById(int id)
    {
        var lead = await _legacy.IntakeLeads.FirstOrDefaultAsync(x => x.Id == id);
        if (lead == null) return NotFound(new { message = "Lead not found" });

        return Ok(MapLead(lead));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpGet("{id}/conflict-check")]
    public async Task<ActionResult<IntakeConflictCheckDto>> RunConflictCheck(int id)
    {
        var lead = await _legacy.IntakeLeads.FirstOrDefaultAsync(x => x.Id == id);
        if (lead == null) return NotFound(new { message = "Lead not found" });

        var reasons = new List<string>();

        if (!string.IsNullOrWhiteSpace(lead.Email))
        {
            var emailExists = await _appDb.Users.AnyAsync(u => u.Email == lead.Email);
            if (emailExists) reasons.Add("Email already exists in system users");
        }

        if (!string.IsNullOrWhiteSpace(lead.PhoneNumber))
        {
            var digits = new string(lead.PhoneNumber.Where(char.IsDigit).ToArray());
            if (int.TryParse(digits, out var phone))
            {
                var phoneExists = await _legacy.Users.AnyAsync(u => u.Phon_Number == phone);
                if (phoneExists) reasons.Add("Phone number already exists in legacy users");
            }
        }

        if (!string.IsNullOrWhiteSpace(lead.NationalId) && int.TryParse(lead.NationalId, out var nationalId))
        {
            var ssnExists = await _legacy.Users.AnyAsync(u => u.SSN == nationalId);
            if (ssnExists) reasons.Add("National ID already exists in legacy users");
        }

        var hasConflict = reasons.Count > 0;
        lead.ConflictChecked = true;
        lead.HasConflict = hasConflict;
        lead.ConflictDetails = hasConflict ? string.Join("; ", reasons) : "No conflict found";
        lead.UpdatedAt = DateTime.UtcNow;
        await _legacy.SaveChangesAsync();

        return Ok(new IntakeConflictCheckDto
        {
            HasConflict = hasConflict,
            Details = lead.ConflictDetails ?? string.Empty
        });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{id}/qualify")]
    public async Task<ActionResult<IntakeLeadDto>> QualifyLead(int id, [FromBody] QualifyIntakeLeadDto dto)
    {
        var lead = await _legacy.IntakeLeads.FirstOrDefaultAsync(x => x.Id == id);
        if (lead == null) return NotFound(new { message = "Lead not found" });

        lead.Status = dto.IsQualified ? "Qualified" : "Rejected";
        lead.QualificationNotes = dto.Notes;
        lead.UpdatedAt = DateTime.UtcNow;
        await _legacy.SaveChangesAsync();

        return Ok(MapLead(lead));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{id}/assign")]
    public async Task<ActionResult<IntakeLeadDto>> AssignLead(int id, [FromBody] AssignIntakeLeadDto dto)
    {
        var lead = await _legacy.IntakeLeads.FirstOrDefaultAsync(x => x.Id == id);
        if (lead == null) return NotFound(new { message = "Lead not found" });

        var exists = await _legacy.Employees.AnyAsync(x => x.id == dto.AssignedEmployeeId);
        if (!exists) return BadRequest(new { message = "Assigned employee not found" });

        lead.AssignedEmployeeId = dto.AssignedEmployeeId;
        lead.NextFollowUpAt = dto.NextFollowUpAt;
        lead.AssignedAt = DateTime.UtcNow;
        lead.UpdatedAt = DateTime.UtcNow;

        await _legacy.SaveChangesAsync();

        return Ok(MapLead(lead));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{id}/convert")]
    public async Task<ActionResult<object>> ConvertLead(int id, [FromBody] ConvertIntakeLeadDto dto)
    {
        var lead = await _legacy.IntakeLeads.FirstOrDefaultAsync(x => x.Id == id);
        if (lead == null) return NotFound(new { message = "Lead not found" });
        if (lead.Status == "Converted") return BadRequest(new { message = "Lead already converted" });
        if (lead.HasConflict) return BadRequest(new { message = "Lead has conflict. Resolve before conversion." });

        var maxUserId = await _legacy.Users.MaxAsync(x => (int?)x.Id) ?? 0;
        var maxCustomerId = await _legacy.Customers.MaxAsync(x => (int?)x.Id) ?? 0;
        var maxCaseId = await _legacy.Cases.MaxAsync(x => (int?)x.Id) ?? 0;
        var maxCaseCode = await _legacy.Cases.MaxAsync(x => (int?)x.Code) ?? 0;
        var maxCustCaseId = await _legacy.Custmors_Cases.MaxAsync(x => (int?)x.Id) ?? 0;

        var userNameBase = string.IsNullOrWhiteSpace(lead.Email) ? lead.FullName.Replace(" ", "").ToLowerInvariant() : lead.Email.Split('@')[0].ToLowerInvariant();
        var userName = $"{userNameBase}{maxUserId + 1}";

        var user = new User
        {
            Id = maxUserId + 1,
            Full_Name = Truncate(lead.FullName, 50),
            Address = null,
            Job = "Client",
            Phon_Number = ParseIntOrDefault(lead.PhoneNumber),
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.Today),
            SSN = ParseIntOrDefault(lead.NationalId),
            User_Name = Truncate(userName, 50),
            Password = "ChangeMe123!"
        };

        var customer = new Customer
        {
            Id = maxCustomerId + 1,
            Users_Id = user.Id
        };

        var caseEntity = new Case
        {
            Id = maxCaseId + 1,
            Code = maxCaseCode + 1,
            Invitions_Statment = Truncate(lead.Subject, 50),
            Invition_Type = Truncate(string.IsNullOrWhiteSpace(dto.CaseType) ? (lead.DesiredCaseType ?? "General") : dto.CaseType, 50),
            Invition_Date = DateOnly.FromDateTime(DateTime.Today),
            Total_Amount = Math.Max(0, dto.InitialAmount ?? 0),
            Notes = Truncate(lead.Description ?? string.Empty, 50),
            Status = 0
        };

        var custCase = new Custmors_Case
        {
            Id = maxCustCaseId + 1,
            Case_Id = caseEntity.Code,
            Custmors_Id = customer.Id
        };

        _legacy.Users.Add(user);
        _legacy.Customers.Add(customer);
        _legacy.Cases.Add(caseEntity);
        _legacy.Custmors_Cases.Add(custCase);

        lead.Status = "Converted";
        lead.ConvertedCustomerId = customer.Id;
        lead.ConvertedCaseCode = caseEntity.Code;
        lead.UpdatedAt = DateTime.UtcNow;

        await _legacy.SaveChangesAsync();

        return Ok(new
        {
            message = "Lead converted",
            customerId = customer.Id,
            caseCode = caseEntity.Code,
            userName = user.User_Name,
            temporaryPassword = user.Password
        });
    }

    private static IntakeLeadDto MapLead(IntakeLead x) => new()
    {
        Id = x.Id,
        FullName = x.FullName,
        Email = x.Email,
        PhoneNumber = x.PhoneNumber,
        NationalId = x.NationalId,
        Subject = x.Subject,
        Description = x.Description,
        DesiredCaseType = x.DesiredCaseType,
        Status = x.Status,
        QualificationNotes = x.QualificationNotes,
        ConflictChecked = x.ConflictChecked,
        HasConflict = x.HasConflict,
        ConflictDetails = x.ConflictDetails,
        AssignedEmployeeId = x.AssignedEmployeeId,
        NextFollowUpAt = x.NextFollowUpAt,
        AssignedAt = x.AssignedAt,
        ConvertedCustomerId = x.ConvertedCustomerId,
        ConvertedCaseCode = x.ConvertedCaseCode,
        CreatedAt = x.CreatedAt,
        UpdatedAt = x.UpdatedAt
    };

    private static int ParseIntOrDefault(string? value)
    {
        var digits = new string((value ?? string.Empty).Where(char.IsDigit).ToArray());
        return int.TryParse(digits, out var n) ? n : 0;
    }

    private static string Truncate(string value, int max)
    {
        if (string.IsNullOrEmpty(value)) return string.Empty;
        return value.Length <= max ? value : value[..max];
    }
}
