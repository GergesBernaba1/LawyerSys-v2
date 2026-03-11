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

    public InAppNotificationService(
        ApplicationDbContext applicationDbContext,
        LegacyDbContext legacyDbContext,
        UserManager<ApplicationUser> userManager,
        IUserContext userContext,
        INotificationRealtimePublisher realtimePublisher)
    {
        _applicationDbContext = applicationDbContext;
        _legacyDbContext = legacyDbContext;
        _userManager = userManager;
        _userContext = userContext;
        _realtimePublisher = realtimePublisher;
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
                    Route = caseContext.Route,
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
                    Route = caseContext.Route,
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
