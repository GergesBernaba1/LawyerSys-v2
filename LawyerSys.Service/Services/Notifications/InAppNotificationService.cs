using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Notifications;

public class InAppNotificationService : IInAppNotificationService
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly LegacyDbContext _legacyDbContext;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IUserContext _userContext;
    private readonly INotificationRealtimePublisher _realtimePublisher;
    private readonly INotificationChannelDispatcher _notificationChannelDispatcher;

    public InAppNotificationService(
        ApplicationDbContext applicationDbContext,
        LegacyDbContext legacyDbContext,
        UserManager<ApplicationUser> userManager,
        IUserContext userContext,
        INotificationRealtimePublisher realtimePublisher,
        INotificationChannelDispatcher notificationChannelDispatcher)
    {
        _applicationDbContext = applicationDbContext;
        _legacyDbContext = legacyDbContext;
        _userManager = userManager;
        _userContext = userContext;
        _realtimePublisher = realtimePublisher;
        _notificationChannelDispatcher = notificationChannelDispatcher;
    }

    public async Task NotifySuperAdminsOfTenantRegistrationAsync(Tenant tenant, ApplicationUser adminUser, CancellationToken cancellationToken = default)
    {
        var recipientIds = await GetUserIdsInRolesAsync(new[] { "SUPERADMIN" }, null, cancellationToken);
        if (recipientIds.Count == 0)
        {
            return;
        }

        var actorName = GetDisplayName(adminUser.FullName, adminUser.UserName);
        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                SenderUserId = adminUser.Id,
                TenantId = tenant.Id,
                Type = "TenantRegistrationPending",
                Title = "New tenant registration",
                TitleAr = "تسجيل مكتب جديد",
                Message = $"{actorName} registered tenant \"{tenant.Name}\" and it is awaiting review.",
                MessageAr = $"قام {actorName} بتسجيل المكتب \"{tenant.Name}\" وهو بانتظار المراجعة.",
                Route = "/tenants",
                RelatedEntityType = "Tenant",
                RelatedEntityId = tenant.Id.ToString()
            },
            cancellationToken);
    }

    public async Task NotifySuperAdminsOfDemoRequestAsync(DemoRequest demoRequest, CancellationToken cancellationToken = default)
    {
        var recipientIds = await GetUserIdsInRolesAsync(new[] { "SUPERADMIN" }, null, cancellationToken);
        if (recipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                Type = "DemoRequestPending",
                Title = "New demo request",
                TitleAr = "طلب عرض تجريبي جديد",
                Message = $"{demoRequest.FullName} requested a demo for \"{demoRequest.OfficeName}\".",
                MessageAr = $"قدم {demoRequest.FullName} طلب عرض تجريبي للمكتب \"{demoRequest.OfficeName}\".",
                Route = "/administration",
                RelatedEntityType = "DemoRequest",
                RelatedEntityId = demoRequest.Id.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyTenantAdminsOfStatusChangeAsync(Tenant tenant, bool isActive, CancellationToken cancellationToken = default)
    {
        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN" }, tenant.Id, cancellationToken);
        recipientIds = recipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (recipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = tenant.Id,
                Type = "TenantStatusChanged",
                Title = isActive ? "Tenant activated" : "Tenant deactivated",
                TitleAr = isActive ? "تم تفعيل المكتب" : "تم إيقاف المكتب",
                Message = $"{actor.DisplayName} {(isActive ? "activated" : "deactivated")} your tenant \"{tenant.Name}\".",
                MessageAr = $"قام {actor.DisplayName} {(isActive ? "بتفعيل" : "بإيقاف")} المكتب \"{tenant.Name}\".",
                Route = "/administration",
                RelatedEntityType = "Tenant",
                RelatedEntityId = tenant.Id.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyTenantBillingDueAsync(Tenant tenant, SubscriptionPackage package, DateTime dueDateUtc, int daysRemaining, CancellationToken cancellationToken = default)
    {
        var tenantRecipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, tenant.Id, cancellationToken);
        var superAdminRecipientIds = await GetUserIdsInRolesAsync(new[] { "SUPERADMIN" }, null, cancellationToken);
        var recipientIds = tenantRecipientIds
            .Concat(superAdminRecipientIds)
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (recipientIds.Length == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                TenantId = tenant.Id,
                Type = "TenantBillingDue",
                Title = $"Tenant billing due in {daysRemaining} day{(daysRemaining == 1 ? string.Empty : "s")}",
                TitleAr = daysRemaining == 1 ? "استحقاق فاتورة الاشتراك غداً" : $"استحقاق فاتورة الاشتراك خلال {daysRemaining} أيام",
                Message = $"Tenant \"{tenant.Name}\" has a {MapCycleLabel(package.BillingCycle).ToLowerInvariant()} renewal due on {dueDateUtc:yyyy-MM-dd}.",
                MessageAr = $"اشتراك المكتب \"{tenant.Name}\" يستحق {MapCycleLabelAr(package.BillingCycle)} بتاريخ {dueDateUtc:yyyy-MM-dd}.",
                Route = "/administration",
                RelatedEntityType = "TenantBillingTransaction",
                RelatedEntityId = tenant.Id.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyTenantSubscriptionExpiredAsync(Tenant tenant, SubscriptionPackage package, CancellationToken cancellationToken = default)
    {
        var tenantRecipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, tenant.Id, cancellationToken);
        var superAdminRecipientIds = await GetUserIdsInRolesAsync(new[] { "SUPERADMIN" }, null, cancellationToken);
        var recipientIds = tenantRecipientIds
            .Concat(superAdminRecipientIds)
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (recipientIds.Length == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                TenantId = tenant.Id,
                Type = "TenantSubscriptionExpired",
                Title = "Tenant subscription expired",
                TitleAr = "انتهى اشتراك المكتب",
                Message = $"Tenant \"{tenant.Name}\" no longer has an active {MapCycleLabel(package.BillingCycle).ToLowerInvariant()} subscription.",
                MessageAr = $"انتهى اشتراك المكتب \"{tenant.Name}\" من نوع {MapCycleLabelAr(package.BillingCycle)}.",
                Route = "/administration",
                RelatedEntityType = "TenantSubscription",
                RelatedEntityId = tenant.Id.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyCustomerAddedToCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var customer = await GetCustomerContextAsync(customerId, cancellationToken);
        if (customer == null)
        {
            return;
        }

        if (!string.IsNullOrWhiteSpace(customer.UserId))
        {
            await CreateNotificationsAsync(
                new[] { customer.UserId! },
                new NotificationContent
                {
                    SenderUserId = actor.UserId,
                    TenantId = caseContext.TenantId,
                    Type = "CaseCustomerLinked",
                    Title = "You were added to a case",
                    TitleAr = "تمت إضافتك إلى قضية",
                    Message = $"{actor.DisplayName} linked you to {caseContext.Label}.",
                    MessageAr = $"قام {actor.DisplayName} بربطك بـ {caseContext.LabelAr}.",
                    Route = $"{caseContext.Route}/timeline",
                    RelatedEntityType = "Case",
                    RelatedEntityId = caseCode.ToString()
                },
                cancellationToken);
        }

        if (!caseContext.TenantId.HasValue)
        {
            return;
        }

        var staffIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        staffIds = staffIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (staffIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            staffIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "CaseCustomerLinked",
                Title = "Customer linked to case",
                TitleAr = "تم ربط عميل بالقضية",
                Message = $"{customer.DisplayName} was linked to {caseContext.Label}.",
                MessageAr = $"تم ربط العميل {customer.DisplayName} بـ {caseContext.LabelAr}.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyCustomerRemovedFromCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var customer = await GetCustomerContextAsync(customerId, cancellationToken);
        if (customer == null)
        {
            return;
        }

        if (!string.IsNullOrWhiteSpace(customer.UserId))
        {
            await CreateNotificationsAsync(
                new[] { customer.UserId! },
                new NotificationContent
                {
                    SenderUserId = actor.UserId,
                    TenantId = caseContext.TenantId,
                    Type = "CaseCustomerUnlinked",
                    Title = "You were removed from a case",
                    TitleAr = "تمت إزالتك من قضية",
                    Message = $"{actor.DisplayName} removed you from {caseContext.Label}.",
                    MessageAr = $"قام {actor.DisplayName} بإزالتك من {caseContext.LabelAr}.",
                    Route = "/cases",
                    RelatedEntityType = "Case",
                    RelatedEntityId = caseCode.ToString()
                },
                cancellationToken);
        }

        if (!caseContext.TenantId.HasValue)
        {
            return;
        }

        var staffIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        staffIds = staffIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (staffIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            staffIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "CaseCustomerUnlinked",
                Title = "Customer removed from case",
                TitleAr = "تمت إزالة عميل من القضية",
                Message = $"{customer.DisplayName} was removed from {caseContext.Label}.",
                MessageAr = $"تمت إزالة العميل {customer.DisplayName} من {caseContext.LabelAr}.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyCaseStatusChangedAsync(int caseCode, CaseStatus oldStatus, CaseStatus newStatus, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var customerRecipientIds = await GetCustomerUserIdsForCaseAsync(caseCode, cancellationToken);
        customerRecipientIds = customerRecipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (customerRecipientIds.Count > 0)
        {
            await CreateNotificationsAsync(
                customerRecipientIds,
                new NotificationContent
                {
                    SenderUserId = actor.UserId,
                    TenantId = caseContext.TenantId,
                    Type = "CaseStatusChanged",
                    Title = "Case status updated",
                    TitleAr = "تم تحديث حالة القضية",
                    Message = $"{actor.DisplayName} updated {caseContext.Label} to {MapStatusLabel(oldStatus: null, newStatus)}.",
                    MessageAr = $"قام {actor.DisplayName} بتحديث {caseContext.LabelAr} إلى {MapStatusLabelAr(oldStatus: null, newStatus)}.",
                    Route = $"{caseContext.Route}/timeline",
                    RelatedEntityType = "Case",
                    RelatedEntityId = caseCode.ToString()
                },
                cancellationToken);
        }

        if (!caseContext.TenantId.HasValue)
        {
            return;
        }

        var staffRecipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        staffRecipientIds = staffRecipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (staffRecipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            staffRecipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "CaseStatusChanged",
                Title = "Case status updated",
                TitleAr = "تم تحديث حالة القضية",
                Message = $"{actor.DisplayName} changed {caseContext.Label} from {MapStatusLabel(oldStatus, null)} to {MapStatusLabel(null, newStatus)}.",
                MessageAr = $"قام {actor.DisplayName} بتغيير {caseContext.LabelAr} من {MapStatusLabelAr(oldStatus, null)} إلى {MapStatusLabelAr(null, newStatus)}.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public Task NotifyCaseSitingScheduledAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default)
    {
        var judgeSegment = string.IsNullOrWhiteSpace(judgeName) ? string.Empty : $" with Judge {judgeName}";
        var judgeSegmentAr = string.IsNullOrWhiteSpace(judgeName) ? string.Empty : $" مع القاضي {judgeName}";

        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "CaseSitingScheduled",
            "New case session scheduled",
            "تمت إضافة جلسة جديدة للقضية",
            caseContext => $"A new session was scheduled for {caseContext.Label} on {sitingTime:yyyy-MM-dd HH:mm}{judgeSegment}.",
            caseContext => $"تمت إضافة جلسة جديدة إلى {caseContext.LabelAr} بتاريخ {sitingTime:yyyy-MM-dd HH:mm}{judgeSegmentAr}.",
            sitingId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseSitingUpdatedAsync(int caseCode, int sitingId, DateTime sitingTime, string judgeName, CancellationToken cancellationToken = default)
    {
        var judgeSegment = string.IsNullOrWhiteSpace(judgeName) ? string.Empty : $" with Judge {judgeName}";
        var judgeSegmentAr = string.IsNullOrWhiteSpace(judgeName) ? string.Empty : $" مع القاضي {judgeName}";

        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "CaseSitingUpdated",
            "Case session updated",
            "تم تحديث جلسة القضية",
            caseContext => $"A session for {caseContext.Label} was updated to {sitingTime:yyyy-MM-dd HH:mm}{judgeSegment}.",
            caseContext => $"تم تحديث جلسة {caseContext.LabelAr} إلى {sitingTime:yyyy-MM-dd HH:mm}{judgeSegmentAr}.",
            sitingId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseSitingCancelledAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default)
    {
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "CaseSitingCancelled",
            "Case session cancelled",
            "تم إلغاء جلسة القضية",
            caseContext => $"A scheduled session for {caseContext.Label} was cancelled.",
            caseContext => $"تم إلغاء جلسة مجدولة لـ {caseContext.LabelAr}.",
            sitingId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseDocumentAddedAsync(int caseCode, int documentId, string documentType, CancellationToken cancellationToken = default)
    {
        var safeType = string.IsNullOrWhiteSpace(documentType) ? "document" : documentType.Trim();
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "CaseDocumentAdded",
            "New document added to your case",
            "تمت إضافة مستند جديد إلى قضيتك",
            caseContext => $"{safeType} was added to {caseContext.Label}.",
            caseContext => $"تمت إضافة مستند من نوع {safeType} إلى {caseContext.LabelAr}.",
            documentId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseFileAddedAsync(int caseCode, int fileId, string fileCode, CancellationToken cancellationToken = default)
    {
        var safeFileCode = string.IsNullOrWhiteSpace(fileCode) ? $"file #{fileId}" : fileCode.Trim();
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "CaseFileAdded",
            "New file uploaded to your case",
            "تم رفع ملف جديد إلى قضيتك",
            caseContext => $"{safeFileCode} was uploaded to {caseContext.Label}.",
            caseContext => $"تم رفع الملف {safeFileCode} إلى {caseContext.LabelAr}.",
            fileId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseCourtAddedAsync(int caseCode, int courtId, string courtName, CancellationToken cancellationToken = default)
    {
        var safeCourtName = string.IsNullOrWhiteSpace(courtName) ? $"court #{courtId}" : courtName.Trim();
        return NotifyCaseCourtUpdateAsync(
            caseCode,
            "CaseCourtAdded",
            "Court added to case",
            "تمت إضافة محكمة إلى القضية",
            caseContext => $"{safeCourtName} was added to {caseContext.Label}.",
            caseContext => $"تمت إضافة المحكمة {safeCourtName} إلى {caseContext.LabelAr}.",
            courtId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseCourtRemovedAsync(int caseCode, int courtId, string courtName, CancellationToken cancellationToken = default)
    {
        var safeCourtName = string.IsNullOrWhiteSpace(courtName) ? $"court #{courtId}" : courtName.Trim();
        return NotifyCaseCourtUpdateAsync(
            caseCode,
            "CaseCourtRemoved",
            "Court removed from case",
            "تمت إزالة محكمة من القضية",
            caseContext => $"{safeCourtName} was removed from {caseContext.Label}.",
            caseContext => $"تمت إزالة المحكمة {safeCourtName} من {caseContext.LabelAr}.",
            courtId.ToString(),
            cancellationToken);
    }

    public Task NotifyCaseCourtChangedAsync(int caseCode, int? oldCourtId, string? oldCourtName, int? newCourtId, string? newCourtName, CancellationToken cancellationToken = default)
    {
        var oldCourtLabel = string.IsNullOrWhiteSpace(oldCourtName) ? (oldCourtId.HasValue ? $"court #{oldCourtId.Value}" : "unspecified court") : oldCourtName.Trim();
        var newCourtLabel = string.IsNullOrWhiteSpace(newCourtName) ? (newCourtId.HasValue ? $"court #{newCourtId.Value}" : "unspecified court") : newCourtName.Trim();

        return NotifyCaseCourtUpdateAsync(
            caseCode,
            "CaseCourtChanged",
            "Case court changed",
            "تم تغيير محكمة القضية",
            caseContext => $"{caseContext.Label} moved from {oldCourtLabel} to {newCourtLabel}.",
            caseContext => $"تم نقل {caseContext.LabelAr} من المحكمة {oldCourtLabel} إلى المحكمة {newCourtLabel}.",
            newCourtId?.ToString() ?? oldCourtId?.ToString() ?? caseCode.ToString(),
            cancellationToken);
    }

    public async Task NotifyCustomerPaymentRecordedAsync(int customerId, int paymentId, double amount, DateOnly paymentDate, CancellationToken cancellationToken = default)
    {
        var customer = await GetCustomerContextAsync(customerId, cancellationToken);
        if (customer == null || string.IsNullOrWhiteSpace(customer.UserId))
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        if (string.Equals(customer.UserId, actor.UserId, StringComparison.Ordinal))
        {
            return;
        }

        await CreateNotificationsAsync(
            new[] { customer.UserId! },
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = _userContext.GetTenantId(),
                Type = "CustomerPaymentRecorded",
                Title = "Payment recorded on your account",
                TitleAr = "تم تسجيل دفعة على حسابك",
                Message = $"{actor.DisplayName} recorded a payment of {amount:F2} on {paymentDate:yyyy-MM-dd}.",
                MessageAr = $"قام {actor.DisplayName} بتسجيل دفعة بقيمة {amount:F2} بتاريخ {paymentDate:yyyy-MM-dd}.",
                Route = "/client-portal",
                RelatedEntityType = "BillingPayment",
                RelatedEntityId = paymentId.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyCaseConversationMessageAsync(int caseCode, string messagePreview, bool fromCustomer, bool visibleToCustomer, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var preview = Truncate(messagePreview, 180);

        if (fromCustomer)
        {
            if (!caseContext.TenantId.HasValue)
            {
                return;
            }

            var staffRecipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
            staffRecipientIds = staffRecipientIds
                .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
                .Distinct(StringComparer.Ordinal)
                .ToList();

            if (staffRecipientIds.Count == 0)
            {
                return;
            }

            await CreateNotificationsAsync(
                staffRecipientIds,
                new NotificationContent
                {
                    SenderUserId = actor.UserId,
                    TenantId = caseContext.TenantId,
                    Type = "CaseConversationMessage",
                    Title = "New client message",
                    TitleAr = "رسالة جديدة من العميل",
                    Message = $"{actor.DisplayName} sent a new message on {caseContext.Label}: {preview}",
                    MessageAr = $"أرسل {actor.DisplayName} رسالة جديدة على {caseContext.LabelAr}: {preview}",
                    Route = caseContext.Route,
                    RelatedEntityType = "Case",
                    RelatedEntityId = caseCode.ToString()
                },
                cancellationToken);

            return;
        }

        if (!visibleToCustomer)
        {
            return;
        }

        var customerRecipientIds = await GetCustomerUserIdsForCaseAsync(caseCode, cancellationToken);
        customerRecipientIds = customerRecipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (customerRecipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            customerRecipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "CaseConversationMessage",
                Title = "New office message",
                TitleAr = "رسالة جديدة من المكتب",
                Message = $"{actor.DisplayName} sent a new update on {caseContext.Label}: {preview}",
                MessageAr = $"أرسل {actor.DisplayName} تحديثاً جديداً على {caseContext.LabelAr}: {preview}",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public Task NotifyRequestedDocumentCreatedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default)
    {
        var safeTitle = string.IsNullOrWhiteSpace(title) ? "requested document" : title.Trim();
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "RequestedDocumentCreated",
            "Document requested from you",
            "تم طلب مستند منك",
            caseContext => $"The office requested \"{safeTitle}\" for {caseContext.Label}.",
            caseContext => $"طلب المكتب المستند \"{safeTitle}\" للقضية {caseContext.LabelAr}.",
            requestId.ToString(),
            cancellationToken);
    }

    public async Task NotifyRequestedDocumentSubmittedAsync(int caseCode, long requestId, string title, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null || !caseContext.TenantId.HasValue)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        recipientIds = recipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (recipientIds.Count == 0)
        {
            return;
        }

        var safeTitle = string.IsNullOrWhiteSpace(title) ? "requested document" : title.Trim();
        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "RequestedDocumentSubmitted",
                Title = "Client uploaded a requested document",
                TitleAr = "قام العميل برفع المستند المطلوب",
                Message = $"{actor.DisplayName} uploaded \"{safeTitle}\" for {caseContext.Label}.",
                MessageAr = $"قام {actor.DisplayName} برفع المستند \"{safeTitle}\" إلى {caseContext.LabelAr}.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public Task NotifyRequestedDocumentReviewedAsync(int caseCode, long requestId, string title, bool approved, CancellationToken cancellationToken = default)
    {
        var safeTitle = string.IsNullOrWhiteSpace(title) ? "requested document" : title.Trim();
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "RequestedDocumentReviewed",
            approved ? "Requested document approved" : "Requested document needs changes",
            approved ? "تم اعتماد المستند المطلوب" : "المستند المطلوب يحتاج تعديلات",
            caseContext => approved
                ? $"The office approved \"{safeTitle}\" for {caseContext.Label}."
                : $"The office asked for updates to \"{safeTitle}\" for {caseContext.Label}.",
            caseContext => approved
                ? $"اعتمد المكتب المستند \"{safeTitle}\" الخاص بـ {caseContext.LabelAr}."
                : $"طلب المكتب تحديثات على المستند \"{safeTitle}\" الخاص بـ {caseContext.LabelAr}.",
            requestId.ToString(),
            cancellationToken);
    }

    public async Task NotifyPaymentProofSubmittedAsync(int caseCode, long proofId, double amount, CancellationToken cancellationToken = default)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null || !caseContext.TenantId.HasValue)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        recipientIds = recipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (recipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "PaymentProofSubmitted",
                Title = "Client submitted a payment proof",
                TitleAr = "قام العميل بإرسال إثبات دفع",
                Message = $"{actor.DisplayName} submitted a payment proof for {caseContext.Label} worth {amount:F2}.",
                MessageAr = $"قام {actor.DisplayName} بإرسال إثبات دفع للقضية {caseContext.LabelAr} بقيمة {amount:F2}.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public Task NotifyPaymentProofReviewedAsync(int caseCode, long proofId, double amount, bool approved, CancellationToken cancellationToken = default)
    {
        return NotifyCustomersOfCaseUpdateAsync(
            caseCode,
            "PaymentProofReviewed",
            approved ? "Payment proof approved" : "Payment proof rejected",
            approved ? "تم اعتماد إثبات الدفع" : "تم رفض إثبات الدفع",
            caseContext => approved
                ? $"Your payment proof for {caseContext.Label} was approved for {amount:F2}."
                : $"Your payment proof for {caseContext.Label} was rejected. Please review the office note.",
            caseContext => approved
                ? $"تم اعتماد إثبات الدفع الخاص بـ {caseContext.LabelAr} بقيمة {amount:F2}."
                : $"تم رفض إثبات الدفع الخاص بـ {caseContext.LabelAr}. يرجى مراجعة ملاحظة المكتب.",
            proofId.ToString(),
            cancellationToken);
    }

    public async Task NotifyEmployeeCaseAssignedAsync(int employeeId, int caseCode, CancellationToken cancellationToken = default)
    {
        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientUserId = await GetEmployeeUserIdAsync(employeeId, cancellationToken);
        if (string.IsNullOrWhiteSpace(recipientUserId) || string.Equals(recipientUserId, actor.UserId, StringComparison.Ordinal))
        {
            return;
        }

        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        await CreateNotificationsAsync(
            new[] { recipientUserId },
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = "CaseAssignment",
                Title = "Case assigned",
                TitleAr = "تم إسناد قضية",
                Message = $"{actor.DisplayName} assigned you {caseContext.Label}.",
                MessageAr = $"قام {actor.DisplayName} بإسناد {caseContext.LabelAr} إليك.",
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = caseCode.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyEmployeeTaskAssignedAsync(int employeeId, int taskId, string taskName, DateTime reminderDate, CancellationToken cancellationToken = default)
    {
        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientUserId = await GetEmployeeUserIdAsync(employeeId, cancellationToken);
        if (string.IsNullOrWhiteSpace(recipientUserId) || string.Equals(recipientUserId, actor.UserId, StringComparison.Ordinal))
        {
            return;
        }

        await CreateNotificationsAsync(
            new[] { recipientUserId },
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = _userContext.GetTenantId(),
                Type = "TaskAssignment",
                Title = "Task assigned",
                TitleAr = "تم إسناد مهمة",
                Message = $"{actor.DisplayName} assigned you the task \"{taskName}\" due on {reminderDate:yyyy-MM-dd HH:mm}.",
                MessageAr = $"قام {actor.DisplayName} بإسناد المهمة \"{taskName}\" إليك بموعد تذكير {reminderDate:yyyy-MM-dd HH:mm}.",
                Route = "/tasks",
                RelatedEntityType = "Task",
                RelatedEntityId = taskId.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyEmployeeLeadAssignedAsync(int employeeId, int leadId, string subject, DateTime? nextFollowUpAt, CancellationToken cancellationToken = default)
    {
        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientUserId = await GetEmployeeUserIdAsync(employeeId, cancellationToken);
        if (string.IsNullOrWhiteSpace(recipientUserId) || string.Equals(recipientUserId, actor.UserId, StringComparison.Ordinal))
        {
            return;
        }

        var followUpText = nextFollowUpAt.HasValue
            ? $" Next follow-up: {nextFollowUpAt.Value:yyyy-MM-dd HH:mm}."
            : string.Empty;
        var followUpTextAr = nextFollowUpAt.HasValue
            ? $" المتابعة القادمة: {nextFollowUpAt.Value:yyyy-MM-dd HH:mm}."
            : string.Empty;

        await CreateNotificationsAsync(
            new[] { recipientUserId },
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = _userContext.GetTenantId(),
                Type = "LeadAssignment",
                Title = "Lead assigned",
                TitleAr = "تم إسناد عميل محتمل",
                Message = $"{actor.DisplayName} assigned you the lead \"{subject}\".{followUpText}",
                MessageAr = $"قام {actor.DisplayName} بإسناد العميل المحتمل \"{subject}\" إليك.{followUpTextAr}",
                Route = "/intake",
                RelatedEntityType = "IntakeLead",
                RelatedEntityId = leadId.ToString()
            },
            cancellationToken);
    }

    public async Task NotifyEmployeeConsultationAssignedAsync(int employeeId, int consultationId, string subject, DateTime consultationDate, CancellationToken cancellationToken = default)
    {
        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientUserId = await GetEmployeeUserIdAsync(employeeId, cancellationToken);
        if (string.IsNullOrWhiteSpace(recipientUserId) || string.Equals(recipientUserId, actor.UserId, StringComparison.Ordinal))
        {
            return;
        }

        var safeSubject = string.IsNullOrWhiteSpace(subject) ? $"Consultation #{consultationId}" : subject.Trim();
        await CreateNotificationsAsync(
            new[] { recipientUserId },
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = _userContext.GetTenantId(),
                Type = "ConsultationAssignment",
                Title = "Consultation assigned",
                TitleAr = "تم إسناد استشارة",
                Message = $"{actor.DisplayName} assigned you the consultation \"{safeSubject}\" on {consultationDate:yyyy-MM-dd HH:mm}.",
                MessageAr = $"قام {actor.DisplayName} بإسناد الاستشارة \"{safeSubject}\" إليك بتاريخ {consultationDate:yyyy-MM-dd HH:mm}.",
                Route = "/consultations",
                RelatedEntityType = "Consultation",
                RelatedEntityId = consultationId.ToString()
            },
            cancellationToken);
    }

    private async Task CreateNotificationsAsync(IEnumerable<string> recipientUserIds, NotificationContent content, CancellationToken cancellationToken)
    {
        var ids = recipientUserIds
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (ids.Length == 0)
        {
            return;
        }

        ids = await FilterRecipientIdsAsync(ids, content, cancellationToken);
        if (ids.Length == 0)
        {
            return;
        }

        var notifications = ids.Select(recipientId => new Notification
        {
            RecipientUserId = recipientId,
            SenderUserId = content.SenderUserId,
            TenantId = content.TenantId,
            Type = content.Type,
            Title = content.Title,
            TitleAr = content.TitleAr,
            Message = content.Message,
            MessageAr = content.MessageAr,
            Route = content.Route,
            RelatedEntityType = content.RelatedEntityType,
            RelatedEntityId = content.RelatedEntityId,
            IsRead = false,
            CreatedAtUtc = DateTime.UtcNow
        });

        _applicationDbContext.Notifications.AddRange(notifications);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        await _realtimePublisher.PublishChangedAsync(ids, cancellationToken);
        await _notificationChannelDispatcher.DispatchAsync(
            ids,
            content.Type,
            content.Title,
            content.TitleAr,
            content.Message,
            content.MessageAr,
            content.Route,
            cancellationToken);
    }

    private async Task<string[]> FilterRecipientIdsAsync(string[] recipientUserIds, NotificationContent content, CancellationToken cancellationToken)
    {
        var allowed = await FilterByGlobalPreferencesAsync(recipientUserIds, content.Type, cancellationToken);
        if (allowed.Length == 0)
        {
            return allowed;
        }

        if (!string.Equals(content.RelatedEntityType, "Case", StringComparison.OrdinalIgnoreCase)
            || !int.TryParse(content.RelatedEntityId, out var caseCode))
        {
            return allowed;
        }

        return await FilterByCaseNotificationSettingsAsync(allowed, caseCode, cancellationToken);
    }

    private async Task<string[]> FilterByGlobalPreferencesAsync(string[] recipientUserIds, string notificationType, CancellationToken cancellationToken)
    {
        var preferences = await _applicationDbContext.UserNotificationPreferences
            .AsNoTracking()
            .Where(item => recipientUserIds.Contains(item.UserId))
            .ToListAsync(cancellationToken);

        if (preferences.Count == 0)
        {
            return recipientUserIds;
        }

        return recipientUserIds
            .Where(id =>
            {
                var preference = preferences.FirstOrDefault(item => item.UserId == id);
                return preference == null || IsAllowedByPreference(preference, notificationType);
            })
            .ToArray();
    }

    private async Task<string[]> FilterByCaseNotificationSettingsAsync(string[] recipientUserIds, int caseCode, CancellationToken cancellationToken)
    {
        var users = await _applicationDbContext.Users
            .AsNoTracking()
            .Where(user => recipientUserIds.Contains(user.Id))
            .Select(user => new { user.Id, user.NormalizedUserName })
            .ToListAsync(cancellationToken);

        if (users.Count == 0)
        {
            return recipientUserIds;
        }

        var normalizedNames = users
            .Select(user => user.NormalizedUserName)
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (normalizedNames.Count == 0)
        {
            return recipientUserIds;
        }

        var customers = await _legacyDbContext.Customers
            .AsNoTracking()
            .Where(customer => normalizedNames.Contains(customer.Users.User_Name.ToUpper()))
            .Select(customer => new
            {
                customer.Id,
                NormalizedUserName = customer.Users.User_Name.ToUpper()
            })
            .ToListAsync(cancellationToken);

        if (customers.Count == 0)
        {
            return recipientUserIds;
        }

        var customerIds = customers.Select(item => item.Id).Distinct().ToList();
        var mutedCustomers = await _legacyDbContext.CustomerCaseNotificationSettings
            .AsNoTracking()
            .Where(item => item.CaseCode == caseCode && customerIds.Contains(item.CustomerId) && !item.NotificationsEnabled)
            .Select(item => item.CustomerId)
            .ToListAsync(cancellationToken);

        if (mutedCustomers.Count == 0)
        {
            return recipientUserIds;
        }

        var mutedNames = customers
            .Where(item => mutedCustomers.Contains(item.Id))
            .Select(item => item.NormalizedUserName)
            .ToHashSet(StringComparer.Ordinal);

        return users
            .Where(user => string.IsNullOrWhiteSpace(user.NormalizedUserName) || !mutedNames.Contains(user.NormalizedUserName))
            .Select(user => user.Id)
            .ToArray();
    }

    private async Task<List<string>> GetUserIdsInRolesAsync(IEnumerable<string> normalizedRoleNames, int? tenantId, CancellationToken cancellationToken)
    {
        var roles = normalizedRoleNames
            .Where(role => !string.IsNullOrWhiteSpace(role))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (roles.Length == 0)
        {
            return new List<string>();
        }

        var query =
            from user in _applicationDbContext.Users.AsNoTracking()
            join userRole in _applicationDbContext.UserRoles.AsNoTracking() on user.Id equals userRole.UserId
            join role in _applicationDbContext.Roles.AsNoTracking() on userRole.RoleId equals role.Id
            where role.NormalizedName != null && roles.Contains(role.NormalizedName)
            select new { user.Id, user.TenantId };

        if (tenantId.HasValue)
        {
            query = query.Where(item => item.TenantId == tenantId.Value);
        }

        return await query
            .Select(item => item.Id)
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    private async Task<ActorContext> GetCurrentActorAsync(CancellationToken cancellationToken)
    {
        var userId = _userContext.GetUserId();
        if (!string.IsNullOrWhiteSpace(userId))
        {
            var actor = await _applicationDbContext.Users
                .AsNoTracking()
                .Where(user => user.Id == userId)
                .Select(user => new { user.Id, user.FullName, user.UserName })
                .FirstOrDefaultAsync(cancellationToken);

            if (actor != null)
            {
                return new ActorContext(actor.Id, GetDisplayName(actor.FullName, actor.UserName));
            }
        }

        return new ActorContext(null, GetDisplayName(null, _userContext.GetUserName()));
    }

    private async Task<CaseContext?> GetCaseContextAsync(int caseCode, CancellationToken cancellationToken)
    {
        var data = await _legacyDbContext.Cases
            .AsNoTracking()
            .Where(item => item.Code == caseCode)
            .Select(item => new
            {
                item.Code,
                item.Invitions_Statment
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (data == null)
        {
            return null;
        }

        var label = string.IsNullOrWhiteSpace(data.Invitions_Statment)
            ? $"case #{data.Code}"
            : $"case #{data.Code} ({data.Invitions_Statment})";
        var labelAr = string.IsNullOrWhiteSpace(data.Invitions_Statment)
            ? $"القضية رقم {data.Code}"
            : $"القضية رقم {data.Code} ({data.Invitions_Statment})";

        return new CaseContext(_userContext.GetTenantId(), label, labelAr, $"/cases/{data.Code}");
    }

    private async Task<CustomerContext?> GetCustomerContextAsync(int customerId, CancellationToken cancellationToken)
    {
        var data = await _legacyDbContext.Customers
            .AsNoTracking()
            .Where(customer => customer.Id == customerId)
            .Select(customer => new
            {
                customer.Id,
                FullName = customer.Users.Full_Name,
                UserName = customer.Users.User_Name
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (data == null)
        {
            return null;
        }

        return new CustomerContext(
            data.Id,
            GetDisplayName(data.FullName, data.UserName),
            await FindApplicationUserIdByUserNameAsync(data.UserName, cancellationToken));
    }

    private async Task<List<string>> GetCustomerUserIdsForCaseAsync(int caseCode, CancellationToken cancellationToken)
    {
        var userNames = await _legacyDbContext.Custmors_Cases
            .AsNoTracking()
            .Where(item => item.Case_Id == caseCode)
            .Select(item => item.Custmors.Users.User_Name)
            .Where(userName => !string.IsNullOrWhiteSpace(userName))
            .Distinct()
            .ToListAsync(cancellationToken);

        if (userNames.Count == 0)
        {
            return new List<string>();
        }

        var normalizedNames = userNames
            .Select(userName => _userManager.NormalizeName(userName))
            .Where(normalizedName => !string.IsNullOrWhiteSpace(normalizedName))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (normalizedNames.Length == 0)
        {
            return new List<string>();
        }

        return await _applicationDbContext.Users
            .AsNoTracking()
            .Where(user => user.NormalizedUserName != null && normalizedNames.Contains(user.NormalizedUserName))
            .Select(user => user.Id)
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    private async Task<string?> FindApplicationUserIdByUserNameAsync(string? userName, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(userName))
        {
            return null;
        }

        var normalizedUserName = _userManager.NormalizeName(userName);
        if (string.IsNullOrWhiteSpace(normalizedUserName))
        {
            return null;
        }

        return await _applicationDbContext.Users
            .AsNoTracking()
            .Where(user => user.NormalizedUserName == normalizedUserName)
            .Select(user => user.Id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    private async Task<string?> GetEmployeeUserIdAsync(int employeeId, CancellationToken cancellationToken)
    {
        var userName = await _legacyDbContext.Employees
            .AsNoTracking()
            .Where(employee => employee.id == employeeId)
            .Select(employee => employee.Users.User_Name)
            .FirstOrDefaultAsync(cancellationToken);

        return await FindApplicationUserIdByUserNameAsync(userName, cancellationToken);
    }

    private async Task NotifyCustomersOfCaseUpdateAsync(
        int caseCode,
        string type,
        string title,
        string titleAr,
        Func<CaseContext, string> buildMessage,
        Func<CaseContext, string> buildMessageAr,
        string relatedEntityId,
        CancellationToken cancellationToken)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);
        var recipientIds = await GetCustomerUserIdsForCaseAsync(caseCode, cancellationToken);
        recipientIds = recipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (recipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            recipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = type,
                Title = title,
                TitleAr = titleAr,
                Message = buildMessage(caseContext),
                MessageAr = buildMessageAr(caseContext),
                Route = $"{caseContext.Route}/timeline",
                RelatedEntityType = "Case",
                RelatedEntityId = relatedEntityId
            },
            cancellationToken);
    }

    private async Task NotifyCaseCourtUpdateAsync(
        int caseCode,
        string type,
        string title,
        string titleAr,
        Func<CaseContext, string> buildMessage,
        Func<CaseContext, string> buildMessageAr,
        string relatedEntityId,
        CancellationToken cancellationToken)
    {
        var caseContext = await GetCaseContextAsync(caseCode, cancellationToken);
        if (caseContext == null)
        {
            return;
        }

        var actor = await GetCurrentActorAsync(cancellationToken);

        var customerRecipientIds = await GetCustomerUserIdsForCaseAsync(caseCode, cancellationToken);
        customerRecipientIds = customerRecipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (customerRecipientIds.Count > 0)
        {
            await CreateNotificationsAsync(
                customerRecipientIds,
                new NotificationContent
                {
                    SenderUserId = actor.UserId,
                    TenantId = caseContext.TenantId,
                    Type = type,
                    Title = title,
                    TitleAr = titleAr,
                    Message = buildMessage(caseContext),
                    MessageAr = buildMessageAr(caseContext),
                    Route = $"{caseContext.Route}/timeline",
                    RelatedEntityType = "Case",
                    RelatedEntityId = relatedEntityId
                },
                cancellationToken);
        }

        if (!caseContext.TenantId.HasValue)
        {
            return;
        }

        var staffRecipientIds = await GetUserIdsInRolesAsync(new[] { "ADMIN", "EMPLOYEE" }, caseContext.TenantId.Value, cancellationToken);
        staffRecipientIds = staffRecipientIds
            .Where(id => !string.Equals(id, actor.UserId, StringComparison.Ordinal))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (staffRecipientIds.Count == 0)
        {
            return;
        }

        await CreateNotificationsAsync(
            staffRecipientIds,
            new NotificationContent
            {
                SenderUserId = actor.UserId,
                TenantId = caseContext.TenantId,
                Type = type,
                Title = title,
                TitleAr = titleAr,
                Message = buildMessage(caseContext),
                MessageAr = buildMessageAr(caseContext),
                Route = caseContext.Route,
                RelatedEntityType = "Case",
                RelatedEntityId = relatedEntityId
            },
            cancellationToken);
    }

    private static string GetDisplayName(string? fullName, string? userName)
    {
        if (!string.IsNullOrWhiteSpace(fullName))
        {
            return fullName;
        }

        if (!string.IsNullOrWhiteSpace(userName))
        {
            return userName;
        }

        return "System";
    }

    private static string Truncate(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        if (trimmed.Length <= maxLength)
        {
            return trimmed;
        }

        return $"{trimmed[..maxLength]}...";
    }

    private static string MapStatusLabel(CaseStatus? oldStatus, CaseStatus? newStatus)
    {
        var status = newStatus ?? oldStatus;
        return status switch
        {
            CaseStatus.New => "New",
            CaseStatus.InProgress => "In Progress",
            CaseStatus.AwaitingHearing => "Awaiting Hearing",
            CaseStatus.Closed => "Closed",
            CaseStatus.Won => "Won",
            CaseStatus.Lost => "Lost",
            _ => "Updated"
        };
    }

    private static string MapStatusLabelAr(CaseStatus? oldStatus, CaseStatus? newStatus)
    {
        var status = newStatus ?? oldStatus;
        return status switch
        {
            CaseStatus.New => "جديدة",
            CaseStatus.InProgress => "قيد التنفيذ",
            CaseStatus.AwaitingHearing => "بانتظار الجلسة",
            CaseStatus.Closed => "مغلقة",
            CaseStatus.Won => "مكسوبة",
            CaseStatus.Lost => "مخسورة",
            _ => "محدثة"
        };
    }

    private static string MapCycleLabel(SubscriptionBillingCycle billingCycle)
    {
        return billingCycle == SubscriptionBillingCycle.Annual ? "Annual" : "Monthly";
    }

    private static string MapCycleLabelAr(SubscriptionBillingCycle billingCycle)
    {
        return billingCycle == SubscriptionBillingCycle.Annual ? "سنوي" : "شهري";
    }

    private static bool IsAllowedByPreference(UserNotificationPreference preference, string notificationType)
    {
        return notificationType switch
        {
            "CustomerPaymentRecorded" or "PaymentProofReviewed" => preference.BillingUpdatesEnabled,
            "RequestedDocumentCreated" or "RequestedDocumentReviewed" => preference.DocumentRequestsEnabled,
            "CaseConversationMessage" => preference.ConversationUpdatesEnabled,
            "CaseAssignment" or "CaseStatusChanged" or "CaseSitingScheduled" or "CaseSitingUpdated" or "CaseSitingCancelled" or "CaseDocumentAdded" or "CaseFileAdded" or "CaseCourtAdded" or "CaseCourtRemoved" or "CaseCourtChanged" => preference.CaseUpdatesEnabled,
            _ => true
        };
    }

    private sealed record NotificationContent
    {
        public string? SenderUserId { get; init; }
        public int? TenantId { get; init; }
        public string Type { get; init; } = string.Empty;
        public string Title { get; init; } = string.Empty;
        public string TitleAr { get; init; } = string.Empty;
        public string Message { get; init; } = string.Empty;
        public string MessageAr { get; init; } = string.Empty;
        public string? Route { get; init; }
        public string? RelatedEntityType { get; init; }
        public string? RelatedEntityId { get; init; }
    }

    private sealed record ActorContext(string? UserId, string DisplayName);
    private sealed record CaseContext(int? TenantId, string Label, string LabelAr, string Route);
    private sealed record CustomerContext(int CustomerId, string DisplayName, string? UserId);
}
