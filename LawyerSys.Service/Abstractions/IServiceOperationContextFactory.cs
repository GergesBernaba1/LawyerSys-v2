namespace LawyerSys.Services;

public interface IServiceOperationContextFactory
{
    Task<ServiceOperationContext> CreateAsync(CancellationToken cancellationToken = default);
}
