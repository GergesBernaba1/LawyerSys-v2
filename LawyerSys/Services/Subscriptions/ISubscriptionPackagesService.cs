using LawyerSys.DTOs;

namespace LawyerSys.Services.Subscriptions;

public interface ISubscriptionPackagesService
{
    Task<IReadOnlyList<SubscriptionPackagePublicGroupDto>> GetPublicPackagesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<SubscriptionPackageAdminGroupDto>> GetPackagesAsync(CancellationToken cancellationToken = default);
    Task<bool> UpsertPackageGroupAsync(string officeSize, SaveSubscriptionPackageGroupRequest request, CancellationToken cancellationToken = default);
}
