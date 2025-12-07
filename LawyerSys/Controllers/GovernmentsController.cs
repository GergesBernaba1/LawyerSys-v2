using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class GovernmentsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public GovernmentsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<GovernamentDto>>> GetGovernments()
    {
        var govs = await _context.Governaments.ToListAsync();
        return Ok(govs.Select(g => new GovernamentDto { Id = g.Id, GovName = g.Gov_Name }));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<GovernamentDto>> GetGovernment(int id)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return NotFound(new { message = "Government not found" });

        return Ok(new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [HttpPost]
    public async Task<ActionResult<GovernamentDto>> CreateGovernment([FromBody] CreateGovernamentDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var gov = new Governament { Gov_Name = dto.GovName };
        _context.Governaments.Add(gov);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetGovernment), new { id = gov.Id }, new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateGovernment(int id, [FromBody] CreateGovernamentDto dto)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return NotFound(new { message = "Government not found" });

        gov.Gov_Name = dto.GovName;
        await _context.SaveChangesAsync();

        return Ok(new GovernamentDto { Id = gov.Id, GovName = gov.Gov_Name });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteGovernment(int id)
    {
        var gov = await _context.Governaments.FindAsync(id);
        if (gov == null)
            return NotFound(new { message = "Government not found" });

        _context.Governaments.Remove(gov);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Government deleted" });
    }
}
