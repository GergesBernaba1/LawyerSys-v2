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
