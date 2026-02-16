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
public class LegacyUsersController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public LegacyUsersController(LegacyDbContext context)
    {
        _context = context;
    }

    // GET: api/legacyusers
    [HttpGet]
    public async Task<ActionResult<IEnumerable<LegacyUserDto>>> GetUsers()
    {
        var users = await _context.Users.ToListAsync();
        return Ok(users.Select(MapToDto));
    }

    // GET: api/legacyusers/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<LegacyUserDto>> GetUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return NotFound(new { message = "User not found" });

        return Ok(MapToDto(user));
    }

    // GET: api/legacyusers/byusername/{username}
    [HttpGet("byusername/{username}")]
    public async Task<ActionResult<LegacyUserDto>> GetUserByUsername(string username)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.User_Name == username);
        if (user == null)
            return NotFound(new { message = "User not found" });

        return Ok(MapToDto(user));
    }

    // POST: api/legacyusers
    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<LegacyUserDto>> CreateUser([FromBody] CreateLegacyUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if username exists
        if (await _context.Users.AnyAsync(u => u.User_Name == dto.UserName))
            return BadRequest(new { message = "Username already exists" });

        // Get max ID and increment
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

        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, MapToDto(user));
    }

    // PUT: api/legacyusers/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateLegacyUserDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return NotFound(new { message = "User not found" });

        if (dto.FullName != null) user.Full_Name = dto.FullName;
        if (dto.Address != null) user.Address = dto.Address;
        if (dto.Job != null) user.Job = dto.Job;
        if (dto.PhoneNumber != null && int.TryParse(dto.PhoneNumber, out var phone)) user.Phon_Number = phone;
        if (dto.DateOfBirth.HasValue) user.Date_Of_Birth = dto.DateOfBirth.Value;
        if (dto.SSN != null && int.TryParse(dto.SSN, out var ssn)) user.SSN = ssn;

        await _context.SaveChangesAsync();

        return Ok(MapToDto(user));
    }

    // DELETE: api/legacyusers/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users
            .Include(u => u.Customers)
            .Include(u => u.Employees)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
            return NotFound(new { message = "User not found" });

        // Check if user has related records
        if (user.Customers.Any())
            return BadRequest(new { message = "Cannot delete user with associated customers" });

        if (user.Employees.Any())
            return BadRequest(new { message = "Cannot delete user with associated employees" });

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        return Ok(new { message = "User deleted" });
    }

    private static LegacyUserDto MapToDto(User u) => new()
    {
        Id = u.Id,
        FullName = u.Full_Name,
        Address = u.Address,
        Job = u.Job,
        PhoneNumber = u.Phon_Number.ToString(),
        DateOfBirth = u.Date_Of_Birth,
        SSN = u.SSN.ToString(),
        UserName = u.User_Name
    };
}
