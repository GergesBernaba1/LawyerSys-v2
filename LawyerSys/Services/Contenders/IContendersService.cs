using LawyerSys.DTOs;

namespace LawyerSys.Services.Contenders;

public interface IContendersService
{
    Task<QueryResult<ContenderDto>> GetContendersAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default);
    Task<ContenderDto?> GetContenderAsync(int id, CancellationToken cancellationToken = default);
    Task<ContenderDto> CreateContenderAsync(CreateContenderDto dto, CancellationToken cancellationToken = default);
    Task<ContenderDto?> UpdateContenderAsync(int id, UpdateContenderDto dto, CancellationToken cancellationToken = default);
    Task<bool> DeleteContenderAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class QueryResult<T>
{
    public IReadOnlyList<T> Items { get; init; } = Array.Empty<T>();
    public int? TotalCount { get; init; }
    public int? Page { get; init; }
    public int? PageSize { get; init; }
}
