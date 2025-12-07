using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CustomersController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public CustomersController(LegacyDbContext context)
    {
        _context = context;
    }

    // GET: api/customers
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers()
    {
        var customers = await _context.Customers
            .Include(c => c.Users)
            .ToListAsync();

        return Ok(customers.Select(MapToDto));
    }

    // GET: api/customers/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<CustomerDto>> GetCustomer(int id)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (customer == null)
            return NotFound(new { message = "Customer not found" });

        return Ok(MapToDto(customer));
    }

    // POST: api/customers
    [HttpPost]
    public async Task<ActionResult<CustomerDto>> CreateCustomer([FromBody] CreateCustomerDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if user exists
        var user = await _context.Users.FindAsync(dto.UsersId);
        if (user == null)
            return BadRequest(new { message = "User not found" });

        var customer = new Customer
        {
            Users_Id = dto.UsersId
        };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        // Reload with user data
        await _context.Entry(customer).Reference(c => c.Users).LoadAsync();

        return CreatedAtAction(nameof(GetCustomer), new { id = customer.Id }, MapToDto(customer));
    }

    // POST: api/customers/withuser - Create customer with new user
    [HttpPost("withuser")]
    public async Task<ActionResult<CustomerDto>> CreateCustomerWithUser([FromBody] CreateCustomerWithUserDto dto)
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

        var customer = new Customer
        {
            Users_Id = user.Id
        };

        _context.Customers.Add(customer);
        await _context.SaveChangesAsync();

        customer.Users = user;

        return CreatedAtAction(nameof(GetCustomer), new { id = customer.Id }, MapToDto(customer));
    }

    // DELETE: api/customers/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCustomer(int id)
    {
        var customer = await _context.Customers.FindAsync(id);
        if (customer == null)
            return NotFound(new { message = "Customer not found" });

        _context.Customers.Remove(customer);
        await _context.SaveChangesAsync();

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
