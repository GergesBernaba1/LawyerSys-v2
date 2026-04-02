using LawyerSys.DTOs;
using LawyerSys.Services.Contenders;

namespace LawyerSys.Services.Users;

public interface IUsersService
{
    Task<QueryResult<UserDto>> GetUsersAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default);
    Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default);
    Task<UserDto?> GetUserByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<CreateUserResult> CreateUserAsync(CreateUserDto dto, CancellationToken cancellationToken = default);
    Task<UserDto?> UpdateUserAsync(int id, UpdateUserDto dto, CancellationToken cancellationToken = default);
    Task<DeleteUserResult> DeleteUserAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class CreateUserResult
{
    public bool UserNameExists { get; init; }
    public UserDto? User { get; init; }
}

public sealed class DeleteUserResult
{
    public bool NotFound { get; init; }
    public bool HasCustomers { get; init; }
    public bool HasEmployees { get; init; }
}
