using LawyerSys.DTOs;

namespace LawyerSys.Services.Demo;

public interface IDemoRequestsService
{
    Task<ServiceMessageResult> CreateDemoRequestAsync(CreateDemoRequestRequest request, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DemoRequestDto>> GetDemoRequestsAsync(CancellationToken cancellationToken = default);
    Task<ServiceMessageResult> ReviewDemoRequestAsync(int id, ReviewDemoRequestRequest request, string? reviewedByUserId, CancellationToken cancellationToken = default);
}

public sealed class ServiceMessageResult
{
    public bool Success { get; init; }
    public bool NotFound { get; init; }
    public bool InvalidStatus { get; init; }
    public string Message { get; init; } = string.Empty;
}
