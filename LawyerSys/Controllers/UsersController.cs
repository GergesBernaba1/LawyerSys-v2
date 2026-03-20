using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public UsersController(LegacyDbContext context, IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetUsers([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<User> query = _context.Users;

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(u =>
                u.Full_Name.Contains(s) ||
                u.User_Name.Contains(s) ||
                u.Job.Contains(s) ||
                u.Phon_Number.ToString().Contains(s) ||
                u.SSN.ToString().Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(u => u.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<UserDto> { Items = items.Select(MapToDto), TotalCount = total, Page = p, PageSize = ps });
        }

        var users = await query.OrderBy(u => u.Id).ToListAsync();
        return Ok(users.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return this.EntityNotFound<UserDto>(_localizer, "User");
        return Ok(MapToDto(user));
    }

    [HttpGet("byusername/{username}")]
    public async Task<ActionResult<UserDto>> GetUserByUsername(string username)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.User_Name == username);
        if (user == null)
            return this.EntityNotFound<UserDto>(_localizer, "User");
        return Ok(MapToDto(user));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (await _context.Users.AnyAsync(u => u.User_Name == dto.UserName))
            return BadRequest(new { message = _localizer["RegistrationFieldAlreadyUsedMessage", _localizer["RegistrationFieldUserName"].Value].Value });

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
            Password = dto.Password
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, MapToDto(user));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return this.EntityNotFound(_localizer, "User");

        if (dto.FullName != null) user.Full_Name = dto.FullName;
        if (dto.Address != null) user.Address = dto.Address;
        if (dto.Job != null) user.Job = dto.Job;
        if (dto.PhoneNumber != null && int.TryParse(dto.PhoneNumber, out var phone)) user.Phon_Number = phone;
        if (dto.DateOfBirth.HasValue) user.Date_Of_Birth = dto.DateOfBirth.Value;
        if (dto.SSN != null && int.TryParse(dto.SSN, out var ssn)) user.SSN = ssn;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(user));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var user = await _context.Users
            .Include(u => u.Customers)
            .Include(u => u.Employees)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
            return this.EntityNotFound(_localizer, "User");

        if (user.Customers.Any())
            return BadRequest(new { message = _localizer["UserHasCustomers"].Value });

        if (user.Employees.Any())
            return BadRequest(new { message = _localizer["UserHasEmployees"].Value });

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["UserDeleted"].Value });
    }

    private static UserDto MapToDto(User u) => new()
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
