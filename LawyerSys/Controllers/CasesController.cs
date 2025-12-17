using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CasesController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public CasesController(LegacyDbContext context)
    {
        _context = context;
    }

    // GET: api/cases
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CaseDto>>> GetCases()
    {
        var cases = await _context.Cases.ToListAsync();
        return Ok(cases.Select(MapToDto));
    }

    // GET: api/cases/{code}
    [HttpGet("{code}")]
    public async Task<ActionResult<CaseDto>> GetCase(int code)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        return Ok(MapToDto(caseEntity));
    }

    // POST: api/cases
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
            Notes = dto.Notes ?? string.Empty
        };

        _context.Cases.Add(caseEntity);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCase), new { code = caseEntity.Code }, MapToDto(caseEntity));
    }

    // PUT: api/cases/{code}
    [HttpPut("{code}")]
    public async Task<IActionResult> UpdateCase(int code, [FromBody] UpdateCaseDto dto)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        if (dto.InvitionsStatment != null) caseEntity.Invitions_Statment = dto.InvitionsStatment;
        if (dto.InvitionType != null) caseEntity.Invition_Type = dto.InvitionType;
        if (dto.InvitionDate.HasValue) caseEntity.Invition_Date = dto.InvitionDate.Value;
        if (dto.TotalAmount.HasValue) caseEntity.Total_Amount = dto.TotalAmount.Value;
        if (dto.Notes != null) caseEntity.Notes = dto.Notes;

        await _context.SaveChangesAsync();

        return Ok(MapToDto(caseEntity));
    }

    // DELETE: api/cases/{code}
    [HttpDelete("{code}")]
    public async Task<IActionResult> DeleteCase(int code)
    {
        var caseEntity = await _context.Cases.FindAsync(code);
        if (caseEntity == null)
            return NotFound(new { message = "Case not found" });

        _context.Cases.Remove(caseEntity);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Case deleted" });
    }

    // POST: api/cases/{code}/assign-employee
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

    private static CaseDto MapToDto(Case c) => new()
    {
        Id = c.Id,
        Code = c.Code,
        InvitionsStatment = c.Invitions_Statment,
        InvitionType = c.Invition_Type,
        InvitionDate = c.Invition_Date,
        TotalAmount = c.Total_Amount,
        Notes = c.Notes
    };
}
