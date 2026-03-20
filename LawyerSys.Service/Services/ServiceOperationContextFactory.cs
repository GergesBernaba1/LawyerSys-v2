using System.Globalization;

namespace LawyerSys.Services;

public sealed class ServiceOperationContextFactory : IServiceOperationContextFactory
{
    private readonly IUserContext _userContext;

    public ServiceOperationContextFactory(IUserContext userContext)
    {
        _userContext = userContext;
    }

    public async Task<ServiceOperationContext> CreateAsync(CancellationToken cancellationToken = default)
    {
        var roles = await _userContext.GetUserRolesAsync();
        return new ServiceOperationContext(
            _userContext.GetUserId(),
            _userContext.GetUserName(),
            _userContext.GetTenantId(),
            roles.ToArray(),
            CultureInfo.CurrentUICulture.Name,
            cancellationToken);
    }
}
