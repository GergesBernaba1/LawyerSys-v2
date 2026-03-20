using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.CaseRelations;
using LawyerSys.Services.Notifications;
using LawyerSys.Tests.Infrastructure;
using Xunit;

namespace LawyerSys.Tests;

public class CaseRelationsServiceTests
{
    [Fact]
    public async Task AddCustomerToCase_WhenRelationExists_ReturnsConflict()
    {
        using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(AddCustomerToCase_WhenRelationExists_ReturnsConflict));
        legacyDb.Custmors_Cases.Add(new Custmors_Case { Id = 1, Case_Id = 10, Custmors_Id = 20 });
        await legacyDb.SaveChangesAsync();

        var service = new CaseRelationsService(
            legacyDb,
            new TestNotificationService(),
            new ServiceOperationContextFactory(new TestUserContext("admin-1", "admin", tenantId: 1, roles: new[] { "Admin" })));

        var result = await service.AddCustomerToCaseAsync(10, 20);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("AlreadyLinked", result.MessageKey);
    }

    [Fact]
    public async Task GetCaseSitings_WhenUserCannotAccessCase_ReturnsForbidden()
    {
        using var legacyDb = ControllerRefactorTestHost.CreateLegacyDbContext(nameof(GetCaseSitings_WhenUserCannotAccessCase_ReturnsForbidden));
        var legacyUser = new User
        {
            Id = 7,
            User_Name = "customer.one",
            Full_Name = "Customer One",
            Password = "x",
            Date_Of_Birth = DateOnly.FromDateTime(DateTime.UtcNow),
            Phon_Number = 0,
            Job = string.Empty,
            SSN = 0
        };

        legacyDb.Users.Add(legacyUser);
        legacyDb.Customers.Add(new Customer { Id = 15, Users_Id = legacyUser.Id, Users = legacyUser });
        await legacyDb.SaveChangesAsync();

        var service = new CaseRelationsService(
            legacyDb,
            new TestNotificationService(),
            new ServiceOperationContextFactory(new TestUserContext(userId: "customer-1", userName: "customer.one", tenantId: 1, roles: new[] { "Customer" })));

        var result = await service.GetCaseSitingsAsync(99);

        Assert.Equal(ServiceResultStatus.Forbidden, result.Status);
    }

    private sealed class TestNotificationService : IInAppNotificationService
    {
        public Task NotifySuperAdminsOfTenantRegistrationAsync(Tenant tenant, ApplicationUser adminUser, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifySuperAdminsOfDemoRequestAsync(DemoRequest demoRequest, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyTenantAdminsOfStatusChangeAsync(Tenant tenant, bool isActive, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyTenantBillingDueAsync(Tenant tenant, SubscriptionPackage package, DateTime dueDateUtc, int daysRemaining, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyTenantSubscriptionExpiredAsync(Tenant tenant, SubscriptionPackage package, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCustomerAddedToCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCustomerRemovedFromCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseStatusChangedAsync(int caseCode, CaseStatus oldStatus, CaseStatus newStatus, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseSitingScheduledAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseSitingUpdatedAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseSitingCancelledAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseDocumentAddedAsync(int caseCode, int documentId, string documentType, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseFileAddedAsync(int caseCode, int fileId, string fileCode, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCustomerPaymentRecordedAsync(int customerId, int paymentId, double amount, DateOnly paymentDate, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyCaseConversationMessageAsync(int caseCode, string messagePreview, bool fromCustomer, bool visibleToCustomer, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyRequestedDocumentCreatedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyRequestedDocumentSubmittedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyRequestedDocumentReviewedAsync(int caseCode, long requestId, string title, bool approved, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyPaymentProofSubmittedAsync(int caseCode, long proofId, double amount, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyPaymentProofReviewedAsync(int caseCode, long proofId, double amount, bool approved, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyEmployeeTaskAssignedAsync(int employeeId, int taskId, string taskName, DateTime reminderDate, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyEmployeeLeadAssignedAsync(int employeeId, int leadId, string subject, DateTime? nextFollowUpAt, CancellationToken cancellationToken = default) => Task.CompletedTask;
        public Task NotifyEmployeeConsultationAssignedAsync(int employeeId, int consultationId, string subject, DateTime consultationDate, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }
}
