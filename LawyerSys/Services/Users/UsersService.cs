using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services.Contenders;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Users;

public sealed class UsersService : IUsersService
{
    private readonly LegacyDbContext _context;

    public UsersService(LegacyDbContext context)
    {
        _context = context;
    }

    public async Task<QueryResult<UserDto>> GetUsersAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default)
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
            var total = await query.CountAsync(cancellationToken);
            var items = await query.OrderBy(u => u.Id).Skip((p - 1) * ps).Take(ps).ToListAsync(cancellationToken);
            return new QueryResult<UserDto>
            {
                Items = items.Select(MapToDto).ToList(),
                TotalCount = total,
                Page = p,
                PageSize = ps
            };
        }

        var users = await query.OrderBy(u => u.Id).ToListAsync(cancellationToken);
        return new QueryResult<UserDto> { Items = users.Select(MapToDto).ToList() };
    }

    public async Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FindAsync([id], cancellationToken);
        return user == null ? null : MapToDto(user);
    }

    public async Task<UserDto?> GetUserByUsernameAsync(string username, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.User_Name == username, cancellationToken);
        return user == null ? null : MapToDto(user);
    }

    public async Task<CreateUserResult> CreateUserAsync(CreateUserDto dto, CancellationToken cancellationToken = default)
    {
        if (await _context.Users.AnyAsync(u => u.User_Name == dto.UserName, cancellationToken))
        {
            return new CreateUserResult { UserNameExists = true };
        }

        var maxId = await _context.Users.MaxAsync(u => (int?)u.Id, cancellationToken) ?? 0;

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
        await _context.SaveChangesAsync(cancellationToken);
        return new CreateUserResult { User = MapToDto(user) };
    }

    public async Task<UserDto?> UpdateUserAsync(int id, UpdateUserDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FindAsync([id], cancellationToken);
        if (user == null)
        {
            return null;
        }

        if (dto.FullName != null)
        {
            user.Full_Name = dto.FullName;
        }
        if (dto.Address != null)
        {
            user.Address = dto.Address;
        }
        if (dto.Job != null)
        {
            user.Job = dto.Job;
        }
        if (dto.PhoneNumber != null && int.TryParse(dto.PhoneNumber, out var phone))
        {
            user.Phon_Number = phone;
        }
        if (dto.DateOfBirth.HasValue)
        {
            user.Date_Of_Birth = dto.DateOfBirth.Value;
        }
        if (dto.SSN != null && int.TryParse(dto.SSN, out var ssn))
        {
            user.SSN = ssn;
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapToDto(user);
    }

    public async Task<DeleteUserResult> DeleteUserAsync(int id, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .Include(u => u.Customers)
            .Include(u => u.Employees)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

        if (user == null)
        {
            return new DeleteUserResult { NotFound = true };
        }

        if (user.Customers.Any())
        {
            return new DeleteUserResult { HasCustomers = true };
        }

        if (user.Employees.Any())
        {
            return new DeleteUserResult { HasEmployees = true };
        }

        _context.Users.Remove(user);
        await _context.SaveChangesAsync(cancellationToken);
        return new DeleteUserResult();
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
