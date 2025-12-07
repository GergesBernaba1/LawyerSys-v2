using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EmployeesController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public EmployeesController(LegacyDbContext context)
    {
        _context = context;
    }

    // GET: api/employees
    [HttpGet]
    public async Task<ActionResult<IEnumerable<EmployeeDto>>> GetEmployees()
    {
        var employees = await _context.Employees
            .Include(e => e.Users)
            .ToListAsync();

        return Ok(employees.Select(MapToDto));
    }

    // GET: api/employees/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<EmployeeDto>> GetEmployee(int id)
    {
        var employee = await _context.Employees
            .Include(e => e.Users)
            .FirstOrDefaultAsync(e => e.id == id);

        if (employee == null)
            return NotFound(new { message = "Employee not found" });

        return Ok(MapToDto(employee));
    }

    // POST: api/employees
    [HttpPost]
    public async Task<ActionResult<EmployeeDto>> CreateEmployee([FromBody] CreateEmployeeDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if user exists
        var user = await _context.Users.FindAsync(dto.UsersId);
        if (user == null)
            return BadRequest(new { message = "User not found" });

        var employee = new Employee
        {
            Salary = dto.Salary,
            Users_Id = dto.UsersId
        };

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        // Reload with user data
        await _context.Entry(employee).Reference(e => e.Users).LoadAsync();

        return CreatedAtAction(nameof(GetEmployee), new { id = employee.id }, MapToDto(employee));
    }

    // POST: api/employees/withuser - Create employee with new user
    [HttpPost("withuser")]
    public async Task<ActionResult<EmployeeDto>> CreateEmployeeWithUser([FromBody] CreateEmployeeWithUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if username exists
        if (await _context.Users.AnyAsync(u => u.User_Name == dto.UserName))
            return BadRequest(new { message = "Username already exists" });

        // Get max user ID and increment
        var maxId = await _context.Users.MaxAsync(u => (int?)u.Id) ?? 0;

        var user = new User
        {
            Id = maxId + 1,
            Full_Name = dto.FullName,
            Address = dto.Address,
            Job = dto.Job,
            Phon_Number = int.TryParse(dto.PhoneNumber, out var phone) ? phone : 0,
            Date_Of_Birth = dto.DateOfBirth,
            SSN = int.TryParse(dto.SSN, out var ssn) ? ssn : 0,
            User_Name = dto.UserName,
            Password = dto.Password // Note: In production, hash this password
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        var employee = new Employee
        {
            Salary = dto.Salary,
            Users_Id = user.Id
        };

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        employee.Users = user;

        return CreatedAtAction(nameof(GetEmployee), new { id = employee.id }, MapToDto(employee));
    }

    // PUT: api/employees/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeDto dto)
    {
        var employee = await _context.Employees
            .Include(e => e.Users)
            .FirstOrDefaultAsync(e => e.id == id);

        if (employee == null)
            return NotFound(new { message = "Employee not found" });

        if (dto.Salary.HasValue)
            employee.Salary = dto.Salary.Value;

        await _context.SaveChangesAsync();

        return Ok(MapToDto(employee));
    }

    // DELETE: api/employees/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null)
            return NotFound(new { message = "Employee not found" });

        _context.Employees.Remove(employee);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Employee deleted" });
    }

    private static EmployeeDto MapToDto(Employee e) => new()
    {
        Id = e.id,
        Salary = e.Salary,
        UsersId = e.Users_Id,
        User = e.Users != null ? new LegacyUserDto
        {
            Id = e.Users.Id,
            FullName = e.Users.Full_Name,
            Address = e.Users.Address,
            Job = e.Users.Job,
            PhoneNumber = e.Users.Phon_Number.ToString(),
            DateOfBirth = e.Users.Date_Of_Birth,
            SSN = e.Users.SSN.ToString(),
            UserName = e.Users.User_Name
        } : null
    };
}
