using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[Authorize]
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
    public async Task<ActionResult<IEnumerable<ConsulationDto>>> GetConsulations([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Consulation> query = _context.Consulations;

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c => c.Consultion_State.Contains(s) || c.Type.Contains(s) || c.Subject.Contains(s) || c.Descraption.Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<ConsulationDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = p,
                PageSize = ps
            });
        }

        var consulations = await query.OrderBy(c => c.Id).ToListAsync();
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

    [Authorize(Policy = "EmployeeOrAdmin")]
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

    [Authorize(Policy = "EmployeeOrAdmin")]
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

    [Authorize(Policy = "EmployeeOrAdmin")]
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

    // ========== CONSULTATION - CUSTOMER RELATIONS ==========

    [HttpGet("{id}/customers")]
    public async Task<ActionResult> GetConsulationCustomers(int id)
    {
        var exists = await _context.Consulations.AnyAsync(c => c.Id == id);
        if (!exists)
            return NotFound(new { message = "Consultation not found" });

        var relations = await _context.Consltitions_Custmors
            .Include(r => r.Customer)
                .ThenInclude(c => c.Users)
            .Where(r => r.Consl_Id == id)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            CustomerId = r.Customer_Id,
            CustomerName = r.Customer?.Users?.Full_Name
        }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{id}/customers/{customerId}")]
    public async Task<ActionResult> AddCustomerToConsulation(int id, int customerId)
    {
        var consulationExists = await _context.Consulations.AnyAsync(c => c.Id == id);
        if (!consulationExists)
            return NotFound(new { message = "Consultation not found" });

        var customerExists = await _context.Customers.AnyAsync(c => c.Id == customerId);
        if (!customerExists)
            return NotFound(new { message = "Customer not found" });

        var exists = await _context.Consltitions_Custmors
            .AnyAsync(r => r.Consl_Id == id && r.Customer_Id == customerId);

        if (exists)
            return BadRequest(new { message = "Customer already linked to this consultation" });

        var relation = new Consltitions_Custmor
        {
            Consl_Id = id,
            Customer_Id = customerId
        };

        _context.Consltitions_Custmors.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Customer added to consultation", id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}/customers/{customerId}")]
    public async Task<ActionResult> RemoveCustomerFromConsulation(int id, int customerId)
    {
        var relation = await _context.Consltitions_Custmors
            .FirstOrDefaultAsync(r => r.Consl_Id == id && r.Customer_Id == customerId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Consltitions_Custmors.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Customer removed from consultation" });
    }

    // ========== CONSULTATION - EMPLOYEE RELATIONS ==========

    [HttpGet("{id}/employees")]
    public async Task<ActionResult> GetConsulationEmployees(int id)
    {
        var exists = await _context.Consulations.AnyAsync(c => c.Id == id);
        if (!exists)
            return NotFound(new { message = "Consultation not found" });

        var relations = await _context.Consulations_Employees
            .Include(r => r.Employee)
                .ThenInclude(e => e.Users)
            .Where(r => r.Consl_ID == id)
            .ToListAsync();

        return Ok(relations.Select(r => new
        {
            Id = r.Id,
            EmployeeId = r.Employee_Id,
            EmployeeName = r.Employee?.Users?.Full_Name
        }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{id}/employees/{employeeId}")]
    public async Task<ActionResult> AddEmployeeToConsulation(int id, int employeeId)
    {
        var consulationExists = await _context.Consulations.AnyAsync(c => c.Id == id);
        if (!consulationExists)
            return NotFound(new { message = "Consultation not found" });

        var employeeExists = await _context.Employees.AnyAsync(e => e.id == employeeId);
        if (!employeeExists)
            return NotFound(new { message = "Employee not found" });

        var exists = await _context.Consulations_Employees
            .AnyAsync(r => r.Consl_ID == id && r.Employee_Id == employeeId);

        if (exists)
            return BadRequest(new { message = "Employee already linked to this consultation" });

        var relation = new Consulations_Employee
        {
            Consl_ID = id,
            Employee_Id = employeeId
        };

        _context.Consulations_Employees.Add(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee added to consultation", id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}/employees/{employeeId}")]
    public async Task<ActionResult> RemoveEmployeeFromConsulation(int id, int employeeId)
    {
        var relation = await _context.Consulations_Employees
            .FirstOrDefaultAsync(r => r.Consl_ID == id && r.Employee_Id == employeeId);

        if (relation == null)
            return NotFound(new { message = "Relation not found" });

        _context.Consulations_Employees.Remove(relation);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee removed from consultation" });
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
