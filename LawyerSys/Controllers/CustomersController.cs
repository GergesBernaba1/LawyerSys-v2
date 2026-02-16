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

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    // GET: api/customers
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers()
    {
        var dtos = (await _customerService.GetCustomersAsync()).ToList();
        return Ok(dtos);
    }

    // GET: api/customers/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<CustomerDto>> GetCustomer(int id)
    {
        var dto = await _customerService.GetCustomerAsync(id);
        if (dto == null) return NotFound(new { message = "Customer not found" });
        return Ok(dto);
    }

    // GET: api/customers/{id}/profile
    [HttpGet("{id}/profile")]
    public async Task<ActionResult<CustomerProfileDto>> GetCustomerProfile(int id)
    {
        var dto = await _customerService.GetCustomerProfileAsync(id);
        if (dto == null) return NotFound(new { message = "Customer not found" });
        return Ok(dto);
    }

    // POST: api/customers
    [HttpPost]
    public async Task<ActionResult<CustomerDto>> CreateCustomer([FromBody] CreateCustomerDto createDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var dto = await _customerService.CreateCustomerAsync(createDto);
            return CreatedAtAction(nameof(GetCustomer), new { id = dto.Id }, dto);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/customers/withuser - Create customer with new user
    [HttpPost("withuser")]
    public async Task<ActionResult<CustomerDto>> CreateCustomerWithUser([FromBody] CreateCustomerWithUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var (customer, tempCredentials) = await _customerService.CreateCustomerWithUserAsync(dto);
            return CreatedAtAction(nameof(GetCustomer), new { id = customer.Id }, new { customer = customer, tempCredentials = new { userName = tempCredentials.UserName, password = tempCredentials.Password } });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

#if false
        // Check if username/email already exists in legacy users or identity users
        if (await _context.Users.AnyAsync(u => u.User_Name == createdUserName) || (await _userManager.FindByNameAsync(createdUserName)) != null || (!string.IsNullOrWhiteSpace(dto.Email) && (await _userManager.FindByEmailAsync(dto.Email)) != null))
            return BadRequest(new { message = "Username or email already exists" });

        // Create legacy user (same as before) but ensure User_Name matches the created identity username
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
            Password = dto.Password // note: legacy stores plaintext; keep current behavior
        };

        _context.Users.Add(legacyUser);
        await _context.SaveChangesAsync();

        var customer = new Customer
        {
            Users_Id = legacyUser.Id
        };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        customer.Users = legacyUser;

        // Create ApplicationUser (Identity) if UserManager available
        string generatedPassword = dto.Password;

        if (_userManager != null)
        {
            // If password not provided, generate a secure temp password
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
                if (_roleManager != null && await _roleManager.RoleExistsAsync("Customer"))
                {
                    await _userManager.AddToRoleAsync(appUser, "Customer");
                }

                // Optionally email credentials and full customer data (localized)
                if (_emailSender != null && !string.IsNullOrWhiteSpace(dto.Email))
                {
                    var emailAddr = dto.Email;
                    var subject = _localizer["AccountCreatedSubject"].Value;
                    var template = _localizer["AccountCreatedBody"].Value;
                    var body = template.Replace("{FullName}", dto.FullName)
                                       .Replace("{Email}", emailAddr)
                                       .Replace("{UserName}", appUser.UserName ?? string.Empty)
                                       .Replace("{Password}", generatedPassword)
                                       .Replace("{Phone}", dto.PhoneNumber)
                                       .Replace("{Job}", dto.Job)
                                       .Replace("{Address}", dto.Address ?? "N/A")
                                       .Replace("{DateOfBirth}", dto.DateOfBirth.ToString("yyyy-MM-dd"))
                                       .Replace("{SSN}", dto.SSN);

                    await _emailSender.SendEmailAsync(emailAddr, subject, body);
                }
                else
                {
                    // No email provided - log that the account was created and requires password reset
                    Console.WriteLine($"Account created for {appUser.UserName} but no email was provided to send credentials.");
                }
            }
            else
            {
                // Log errors but continue; admin can see legacy user created
                Console.WriteLine("Failed to create identity user: " + string.Join(", ", result.Errors.Select(e => e.Description)));
            }
        }

        var responseDto = MapToDto(customer);

        // Attach identity info if available
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

#endif
        // legacy create-with-user implementation removed (migrated to CustomerService)
    }

    // PUT: api/customers/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCustomer(int id, [FromBody] UpdateCustomerDto dto)
    {
        try
        {
            var updated = await _customerService.UpdateCustomerAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // DELETE: api/customers/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCustomer(int id)
    {
        var ok = await _customerService.DeleteCustomerAsync(id);
        if (!ok) return NotFound(new { message = "Customer not found" });
        return Ok(new { message = "Customer deleted" });
    }

    private static CustomerDto MapToDto(Customer c) => new()
    {
        Id = c.Id,
        UsersId = c.Users_Id,
        User = c.Users != null ? new LegacyUserDto
        {
            Id = c.Users.Id,
            FullName = c.Users.Full_Name,
            Address = c.Users.Address,
            Job = c.Users.Job,
            PhoneNumber = c.Users.Phon_Number.ToString(),
            DateOfBirth = c.Users.Date_Of_Birth,
            SSN = c.Users.SSN.ToString(),
            UserName = c.Users.User_Name
        } : null
    };
}
