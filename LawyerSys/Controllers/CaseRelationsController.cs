using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/cases")]
public class CaseRelationsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public CaseRelationsController(LegacyDbContext context)
    {
        _context = context;
    }

    // ========== CASE - CUSTOMER RELATIONS ==========

    [HttpGet("{caseCode}/customers")]
    public async Task<ActionResult> GetCaseCustomers(int caseCode)
    {
        var relations = await _context.Custmors_Cases
            .Include(cc => cc.Custmors)
                .ThenInclude(c => c.Users)
            .Where(cc => cc.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            CustomerId = r.Custmors_Id,
            CustomerName = r.Custmors?.Users?.Full_Name
        }));
    }

    [HttpPost("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> AddCustomerToCase(int caseCode, int customerId)
    {
        // Check if already exists
        var exists = await _context.Custmors_Cases
            .AnyAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customerId);

        if (exists)
            return BadRequest(new { message = "Customer already linked to this case" });

        var relation = new Custmors_Case
        {
            Case_Id = caseCode,
            Custmors_Id = customerId
        };

        _context.Custmors_Cases.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Customer added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> RemoveCustomerFromCase(int caseCode, int customerId)
    {
        var relation = await _context.Custmors_Cases
            .FirstOrDefaultAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customerId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Custmors_Cases.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Customer removed from case" });
    }

    // ========== CASE - CONTENDER RELATIONS ==========

    [HttpGet("{caseCode}/contenders")]
    public async Task<ActionResult> GetCaseContenders(int caseCode)
    {
        var relations = await _context.Cases_Contenders
            .Include(cc => cc.Contender)
            .Where(cc => cc.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            ContenderId = r.Contender_Id,
            ContenderName = r.Contender?.Full_Name
        }));
    }

    [HttpPost("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> AddContenderToCase(int caseCode, int contenderId)
    {
        var exists = await _context.Cases_Contenders
            .AnyAsync(cc => cc.Case_Id == caseCode && cc.Contender_Id == contenderId);

        if (exists)
            return BadRequest(new { message = "Contender already linked to this case" });

        var relation = new Cases_Contender
        {
            Case_Id = caseCode,
            Contender_Id = contenderId
        };

        _context.Cases_Contenders.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Contender added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> RemoveContenderFromCase(int caseCode, int contenderId)
    {
        var relation = await _context.Cases_Contenders
            .FirstOrDefaultAsync(cc => cc.Case_Id == caseCode && cc.Contender_Id == contenderId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Cases_Contenders.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Contender removed from case" });
    }

    // ========== CASE - COURT RELATIONS ==========

    [HttpGet("{caseCode}/courts")]
    public async Task<ActionResult> GetCaseCourts(int caseCode)
    {
        var relations = await _context.Cases_Courts
            .Include(cc => cc.Court)
            .Where(cc => cc.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            CourtId = r.Court_Id,
            CourtName = r.Court?.Name
        }));
    }

    [HttpPost("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> AddCourtToCase(int caseCode, int courtId)
    {
        var exists = await _context.Cases_Courts
            .AnyAsync(cc => cc.Case_Code == caseCode && cc.Court_Id == courtId);

        if (exists)
            return BadRequest(new { message = "Court already linked to this case" });

        var relation = new Cases_Court
        {
            Case_Code = caseCode,
            Court_Id = courtId
        };

        _context.Cases_Courts.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Court added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> RemoveCourtFromCase(int caseCode, int courtId)
    {
        var relation = await _context.Cases_Courts
            .FirstOrDefaultAsync(cc => cc.Case_Code == caseCode && cc.Court_Id == courtId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Cases_Courts.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Court removed from case" });
    }

    // ========== CASE - EMPLOYEE RELATIONS ==========

    [HttpGet("{caseCode}/employees")]
    public async Task<ActionResult> GetCaseEmployees(int caseCode)
    {
        var relations = await _context.Cases_Employees
            .Include(ce => ce.Employee)
                .ThenInclude(e => e.Users)
            .Where(ce => ce.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            EmployeeId = r.Employee_Id,
            EmployeeName = r.Employee?.Users?.Full_Name
        }));
    }

    [HttpPost("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> AddEmployeeToCase(int caseCode, int employeeId)
    {
        var exists = await _context.Cases_Employees
            .AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employeeId);

        if (exists)
            return BadRequest(new { message = "Employee already linked to this case" });

        var relation = new Cases_Employee
        {
            Case_Code = caseCode,
            Employee_Id = employeeId
        };

        _context.Cases_Employees.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> RemoveEmployeeFromCase(int caseCode, int employeeId)
    {
        var relation = await _context.Cases_Employees
            .FirstOrDefaultAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employeeId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Cases_Employees.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee removed from case" });
    }

    // ========== CASE - SITING RELATIONS ==========

    [HttpGet("{caseCode}/sitings")]
    public async Task<ActionResult> GetCaseSitings(int caseCode)
    {
        var relations = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            SitingId = r.Siting_Id,
            SitingDate = r.Siting?.Siting_Date,
            JudgeName = r.Siting?.Judge_Name
        }));
    }

    [HttpPost("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> AddSitingToCase(int caseCode, int sitingId)
    {
        var exists = await _context.Cases_Sitings
            .AnyAsync(cs => cs.Case_Code == caseCode && cs.Siting_Id == sitingId);

        if (exists)
            return BadRequest(new { message = "Siting already linked to this case" });

        var relation = new Cases_Siting
        {
            Case_Code = caseCode,
            Siting_Id = sitingId
        };

        _context.Cases_Sitings.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Siting added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> RemoveSitingFromCase(int caseCode, int sitingId)
    {
        var relation = await _context.Cases_Sitings
            .FirstOrDefaultAsync(cs => cs.Case_Code == caseCode && cs.Siting_Id == sitingId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Cases_Sitings.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Siting removed from case" });
    }

    // ========== CASE - FILE RELATIONS ==========

    [HttpGet("{caseCode}/files")]
    public async Task<ActionResult> GetCaseFiles(int caseCode)
    {
        var relations = await _context.Cases_Files
            .Include(cf => cf.File)
            .Where(cf => cf.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            FileId = r.File_Id,
            FilePath = r.File?.Path,
            FileCode = r.File?.Code
        }));
    }

    [HttpPost("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> AddFileToCase(int caseCode, int fileId)
    {
        var exists = await _context.Cases_Files
            .AnyAsync(cf => cf.Case_Id == caseCode && cf.File_Id == fileId);

        if (exists)
            return BadRequest(new { message = "File already linked to this case" });

        var relation = new Cases_File
        {
            Case_Id = caseCode,
            File_Id = fileId
        };

        _context.Cases_Files.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "File added to case", id = relation.Id });
    }

    [HttpDelete("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> RemoveFileFromCase(int caseCode, int fileId)
    {
        var relation = await _context.Cases_Files
            .FirstOrDefaultAsync(cf => cf.Case_Id == caseCode && cf.File_Id == fileId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Cases_Files.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "File removed from case" });
    }

    // ========== FULL CASE DETAILS ==========

    [HttpGet("{caseCode}/full")]
    public async Task<ActionResult> GetCaseFullDetails(int caseCode)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        var customers = await _context.Custmors_Cases
            .Include(cc => cc.Custmors).ThenInclude(c => c.Users)
            .Where(cc => cc.Case_Id == caseCode)
            .Select(cc => new { cc.Custmors.Id, cc.Custmors.Users.Full_Name })
            .ToListAsync();

        var contenders = await _context.Cases_Contenders
            .Include(cc => cc.Contender)
            .Where(cc => cc.Case_Id == caseCode)
            .Select(cc => new { cc.Contender.Id, cc.Contender.Full_Name })
            .ToListAsync();

        var courts = await _context.Cases_Courts
            .Include(cc => cc.Court)
            .Where(cc => cc.Case_Code == caseCode)
            .Select(cc => new { cc.Court.Id, cc.Court.Name })
            .ToListAsync();

        var employees = await _context.Cases_Employees
            .Include(ce => ce.Employee).ThenInclude(e => e.Users)
            .Where(ce => ce.Case_Code == caseCode)
            .Select(ce => new { ce.Employee.id, ce.Employee.Users.Full_Name })
            .ToListAsync();

        var sitings = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Case_Code == caseCode)
            .Select(cs => new { cs.Siting.Id, cs.Siting.Siting_Date, cs.Siting.Judge_Name })
            .ToListAsync();

        var files = await _context.Cases_Files
            .Include(cf => cf.File)
            .Where(cf => cf.Case_Id == caseCode)
            .Select(cf => new { cf.File.Id, cf.File.Path, cf.File.Code })
            .ToListAsync();

        return Ok(new
        {
            Case = new
            {
                caseEntity.Id,
                caseEntity.Code,
                InvitionsStatment = caseEntity.Invitions_Statment,
                InvitionType = caseEntity.Invition_Type,
                InvitionDate = caseEntity.Invition_Date,
                TotalAmount = caseEntity.Total_Amount,
                caseEntity.Notes
            },
            Customers = customers,
            Contenders = contenders,
            Courts = courts,
            Employees = employees,
            Sitings = sitings,
            Files = files
        });
    }
}
