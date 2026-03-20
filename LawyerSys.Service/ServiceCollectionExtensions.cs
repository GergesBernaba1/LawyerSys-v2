using Microsoft.Extensions.DependencyInjection;

namespace LawyerSys.Services;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddControllerRefactorCoreServices(this IServiceCollection services)
    {
        services.AddScoped<IServiceOperationContextFactory, ServiceOperationContextFactory>();
        return services;
    }
}
