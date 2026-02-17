using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LawyerSys.DTOs;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class EmployeesController : ControllerBase
{
    private readonly IEmployeeService _employeeService;

    public EmployeesController(IEmployeeService employeeService)
    {
        _employeeService = employeeService;
    }

    // GET: api/employees
    [HttpGet]
    public async Task<ActionResult<IEnumerable<EmployeeDto>>> GetEmployees([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var paged = await _employeeService.GetEmployeesAsync(page.Value, pageSize.Value, search);
            return Ok(paged);
        }

        var dtos = (await _employeeService.GetEmployeesAsync()).ToList();
        return Ok(dtos);
    }

    // GET: api/employees/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<EmployeeDto>> GetEmployee(int id)
    {
        var dto = await _employeeService.GetEmployeeAsync(id);
        if (dto == null) return NotFound(new { message = "Employee not found" });
        return Ok(dto);
    }

    // POST: api/employees
    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<EmployeeDto>> CreateEmployee([FromBody] CreateEmployeeDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _employeeService.CreateEmployeeAsync(dto);
            return CreatedAtAction(nameof(GetEmployee), new { id = created.Id }, created);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/employees/withuser - Create employee with new user
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("withuser")]
    public async Task<ActionResult<EmployeeDto>> CreateEmployeeWithUser([FromBody] CreateEmployeeWithUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var (employee, tempCredentials) = await _employeeService.CreateEmployeeWithUserAsync(dto);
            return CreatedAtAction(nameof(GetEmployee), new { id = employee.Id }, new { employee = employee, tempCredentials = new { userName = tempCredentials.UserName, password = tempCredentials.Password } });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // PUT: api/employees/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeDto dto)
    {
        try
        {
            var updated = await _employeeService.UpdateEmployeeAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // DELETE: api/employees/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var ok = await _employeeService.DeleteEmployeeAsync(id);
        if (!ok) return NotFound(new { message = "Employee not found" });
        return Ok(new { message = "Employee deleted" });
    }
}
