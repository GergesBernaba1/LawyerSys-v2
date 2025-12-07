using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ConsulationsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public ConsulationsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ConsulationDto>>> GetConsulations()
    {
        var consulations = await _context.Consulations.ToListAsync();
        return Ok(consulations.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ConsulationDto>> GetConsulation(int id)
    {
        var consulation = await _context.Consulations.FindAsync(id);
        if (consulation == null)
            return NotFound(new { message = "Consultation not found" });

        return Ok(MapToDto(consulation));
    }

    [HttpPost]
    public async Task<ActionResult<ConsulationDto>> CreateConsulation([FromBody] CreateConsulationDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var consulation = new Consulation
        {
            Consultion_State = dto.ConsultionState,
            Type = dto.Type,
            Subject = dto.Subject,
            Descraption = dto.Description,
            Feedback = dto.Feedback ?? string.Empty,
            Notes = dto.Notes ?? string.Empty,
            Date_time = dto.DateTime
        };

        _context.Consulations.Add(consulation);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetConsulation), new { id = consulation.Id }, MapToDto(consulation));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateConsulation(int id, [FromBody] UpdateConsulationDto dto)
    {
        var consulation = await _context.Consulations.FindAsync(id);
        if (consulation == null)
            return NotFound(new { message = "Consultation not found" });

        if (dto.ConsultionState != null) consulation.Consultion_State = dto.ConsultionState;
        if (dto.Type != null) consulation.Type = dto.Type;
        if (dto.Subject != null) consulation.Subject = dto.Subject;
        if (dto.Description != null) consulation.Descraption = dto.Description;
        if (dto.Feedback != null) consulation.Feedback = dto.Feedback;
        if (dto.Notes != null) consulation.Notes = dto.Notes;
        if (dto.DateTime.HasValue) consulation.Date_time = dto.DateTime.Value;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(consulation));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteConsulation(int id)
    {
        var consulation = await _context.Consulations.FindAsync(id);
        if (consulation == null)
            return NotFound(new { message = "Consultation not found" });

        _context.Consulations.Remove(consulation);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Consultation deleted" });
    }

    private static ConsulationDto MapToDto(Consulation c) => new()
    {
        Id = c.Id,
        ConsultionState = c.Consultion_State,
        Type = c.Type,
        Subject = c.Subject,
        Description = c.Descraption,
        Feedback = c.Feedback,
        Notes = c.Notes,
        DateTime = c.Date_time
    };
}
