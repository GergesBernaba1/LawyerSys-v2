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
    Task NotifyCaseSitingScheduledAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default);
    Task NotifyCaseSitingUpdatedAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default);
    Task NotifyCaseSitingCancelledAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default);
    Task NotifyCaseDocumentAddedAsync(int caseCode, int documentId, string documentType, CancellationToken cancellationToken = default);
    Task NotifyCaseFileAddedAsync(int caseCode, int fileId, string fileCode, CancellationToken cancellationToken = default);
    Task NotifyCustomerPaymentRecordedAsync(int customerId, int paymentId, double amount, DateOnly paymentDate, CancellationToken cancellationToken = default);
    Task NotifyCaseConversationMessageAsync(int caseCode, string messagePreview, bool fromCustomer, bool visibleToCustomer, CancellationToken cancellationToken = default);
    Task NotifyRequestedDocumentCreatedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default);
    Task NotifyRequestedDocumentSubmittedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default);
    Task NotifyRequestedDocumentReviewedAsync(int caseCode, long requestId, string title, bool approved, CancellationToken cancellationToken = default);
    Task NotifyPaymentProofSubmittedAsync(int caseCode, long proofId, double amount, CancellationToken cancellationToken = default);
    Task NotifyPaymentProofReviewedAsync(int caseCode, long proofId, double amount, bool approved, CancellationToken cancellationToken = default);
    Task NotifyEmployeeTaskAssignedAsync(int employeeId, int taskId, string taskName, DateTime reminderDate, CancellationToken cancellationToken = default);
    Task NotifyEmployeeLeadAssignedAsync(int employeeId, int leadId, string subject, DateTime? nextFollowUpAt, CancellationToken cancellationToken = default);
    Task NotifyEmployeeConsultationAssignedAsync(int employeeId, int consultationId, string subject, DateTime consultationDate, CancellationToken cancellationToken = default);
}
