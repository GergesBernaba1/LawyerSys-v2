using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using Microsoft.AspNetCore.Identity;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

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
    public async Task<ActionResult<IEnumerable<EmployeeDto>>> GetEmployees()
    {
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
    
#if false
        // Check if username/email already exists in legacy users or identity users
        if (await _context.Users.AnyAsync(u => u.User_Name == createdUserName) || (await _userManager.FindByNameAsync(createdUserName)) != null || (!string.IsNullOrWhiteSpace(dto.Email) && (await _userManager.FindByEmailAsync(dto.Email)) != null))
            return BadRequest(new { message = "Username or email already exists" });

        // Get max user ID and increment
        var maxId = await _context.Users.MaxAsync(u => (int?)u.Id) ?? 0;

        var legacyUser = new User
        {
            Id = maxId + 1,
            Full_Name = dto.FullName,
            Address = dto.Address,
            Job = dto.Job,
            Phon_Number = int.TryParse(dto.PhoneNumber, out var phone) ? phone : 0,
            Date_Of_Birth = dto.DateOfBirth,
            SSN = int.TryParse(dto.SSN, out var ssn) ? ssn : 0,
            User_Name = createdUserName,
            Password = dto.Password // Note: In production, hash this password
        };

        _context.Users.Add(legacyUser);
        await _context.SaveChangesAsync();

        var employee = new Employee
        {
            Salary = dto.Salary,
            Users_Id = legacyUser.Id
        };

        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        employee.Users = legacyUser;

        // Create ApplicationUser for employee in Identity
        string generatedPassword = dto.Password;

        if (_userManager != null)
        {
            if (string.IsNullOrWhiteSpace(generatedPassword))
            {
                generatedPassword = "Temp@" + Guid.NewGuid().ToString("N").Substring(0, 8);
            }

            var appUser = new ApplicationUser
            {
                UserName = createdUserName,
                Email = dto.Email ?? string.Empty,
                FullName = dto.FullName,
                EmailConfirmed = !string.IsNullOrWhiteSpace(dto.Email),
                RequiresPasswordReset = true
            };

            var result = await _userManager.CreateAsync(appUser, generatedPassword);
            if (result.Succeeded)
            {
                if (_roleManager != null && await _roleManager.RoleExistsAsync("Employee"))
                {
                    await _userManager.AddToRoleAsync(appUser, "Employee");
                }

                // Prepare localized email
                if (_emailSender != null && !string.IsNullOrWhiteSpace(dto.Email))
                {
                    var subject = _localizer["AccountCreatedSubject"].Value;
                    var template = _localizer["AccountCreatedBody"].Value;
                    var body = template.Replace("{FullName}", dto.FullName)
                                       .Replace("{Email}", dto.Email ?? string.Empty)
                                       .Replace("{UserName}", appUser.UserName ?? string.Empty)
                                       .Replace("{Password}", generatedPassword)
                                       .Replace("{Phone}", dto.PhoneNumber)
                                       .Replace("{Job}", dto.Job)
                                       .Replace("{Address}", dto.Address ?? "N/A")
                                       .Replace("{DateOfBirth}", dto.DateOfBirth.ToString("yyyy-MM-dd"))
                                       .Replace("{SSN}", dto.SSN);

                    await _emailSender.SendEmailAsync(dto.Email, subject, body);
                }
                else
                {
                    Console.WriteLine($"Account created for {appUser.UserName} but no email was provided to send credentials.");
                }
            }
            else
            {
                Console.WriteLine("Failed to create identity user: " + string.Join(", ", result.Errors.Select(e => e.Description)));
            }
        }

        var responseDto = MapToDto(employee);
        var createdAppUser = await _userManager.FindByNameAsync(createdUserName);
        if (createdAppUser != null)
        {
            responseDto.Identity = new IdentityUserInfoDto
            {
                Id = createdAppUser.Id,
                UserName = createdAppUser.UserName ?? string.Empty,
                Email = createdAppUser.Email ?? string.Empty,
                FullName = createdAppUser.FullName ?? string.Empty,
                EmailConfirmed = createdAppUser.EmailConfirmed,
                RequiresPasswordReset = createdAppUser.RequiresPasswordReset
            };
        }

        return CreatedAtAction(nameof(GetEmployee), new { id = employee.id }, new { employee = responseDto, tempCredentials = new { userName = createdUserName, password = generatedPassword } });
#endif
    }

    // PUT: api/employees/{id}
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
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var ok = await _employeeService.DeleteEmployeeAsync(id);
        if (!ok) return NotFound(new { message = "Employee not found" });
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
