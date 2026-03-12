using LawyerSys.DTOs;

namespace LawyerSys.Services.Notifications;

public interface IInAppNotificationService
{
    Task NotifySuperAdminsOfTenantRegistrationAsync(Tenant tenant, ApplicationUser adminUser, CancellationToken cancellationToken = default);
    Task NotifySuperAdminsOfDemoRequestAsync(DemoRequest demoRequest, CancellationToken cancellationToken = default);
    Task NotifyTenantAdminsOfStatusChangeAsync(Tenant tenant, bool isActive, CancellationToken cancellationToken = default);
    Task NotifyTenantBillingDueAsync(Tenant tenant, SubscriptionPackage package, DateTime dueDateUtc, int daysRemaining, CancellationToken cancellationToken = default);
    Task NotifyTenantSubscriptionExpiredAsync(Tenant tenant, SubscriptionPackage package, CancellationToken cancellationToken = default);
    Task NotifyCustomerAddedToCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default);
    Task NotifyCustomerRemovedFromCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default);
    Task NotifyCaseStatusChangedAsync(int caseCode, CaseStatus oldStatus, CaseStatus newStatus, CancellationToken cancellationToken = default);
}
