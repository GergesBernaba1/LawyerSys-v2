using System.Globalization;
using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Notifications;

public sealed class NotificationsQueryService : INotificationsQueryService
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly INotificationRealtimePublisher _realtimePublisher;

    public NotificationsQueryService(
        ApplicationDbContext applicationDbContext,
        INotificationRealtimePublisher realtimePublisher)
    {
        _applicationDbContext = applicationDbContext;
        _realtimePublisher = realtimePublisher;
    }

    public async Task<NotificationListDto> GetNotificationsAsync(string currentUserId, int page, int pageSize, NotificationReadFilter filter, NotificationCategoryFilter category, CancellationToken cancellationToken = default)
    {
        var safePage = Math.Max(page, 1);
        var safePageSize = Math.Clamp(pageSize, 1, 50);
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";

        var query = _applicationDbContext.Notifications
            .AsNoTracking()
            .Where(notification => notification.RecipientUserId == currentUserId)
            .AsQueryable();

        if (filter == NotificationReadFilter.Unread)
        {
            query = query.Where(notification => !notification.IsRead);
        }
        else if (filter == NotificationReadFilter.Read)
        {
            query = query.Where(notification => notification.IsRead);
        }

        query = category switch
        {
            NotificationCategoryFilter.Billing => query.Where(notification => notification.Type.Contains("Billing") || notification.Type.Contains("Payment")),
            NotificationCategoryFilter.Document => query.Where(notification => notification.Type.Contains("Document") || notification.Type.Contains("File")),
            NotificationCategoryFilter.Conversation => query.Where(notification => notification.Type.Contains("Conversation") || notification.Type.Contains("Message")),
            NotificationCategoryFilter.Case => query.Where(notification => notification.Type.Contains("Case") || notification.Type.Contains("Siting")),
            NotificationCategoryFilter.System => query.Where(notification =>
                !notification.Type.Contains("Billing") &&
                !notification.Type.Contains("Payment") &&
                !notification.Type.Contains("Document") &&
                !notification.Type.Contains("File") &&
                !notification.Type.Contains("Conversation") &&
                !notification.Type.Contains("Message") &&
                !notification.Type.Contains("Case") &&
                !notification.Type.Contains("Siting")),
            _ => query
        };

        var totalCount = await query.CountAsync(cancellationToken);
        var itemsRaw = await query
            .OrderByDescending(notification => notification.CreatedAtUtc)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .Select(notification => new
            {
                notification.Id,
                Title = useArabic && !string.IsNullOrWhiteSpace(notification.TitleAr) ? notification.TitleAr : notification.Title,
                Message = useArabic && !string.IsNullOrWhiteSpace(notification.MessageAr) ? notification.MessageAr : notification.Message,
                Action = notification.Type,
                EntityName = notification.RelatedEntityType ?? string.Empty,
                notification.Route,
                Timestamp = notification.CreatedAtUtc,
                notification.IsRead
            })
            .ToListAsync(cancellationToken);
        var items = itemsRaw.Select(notification => new NotificationItemDto
        {
            Id = notification.Id,
            Title = notification.Title,
            Message = notification.Message,
            Action = notification.Action,
            Category = MapCategory(notification.Action),
            EntityName = notification.EntityName,
            Route = notification.Route,
            Timestamp = notification.Timestamp,
            IsRead = notification.IsRead
        }).ToList();

        var unreadCount = await _applicationDbContext.Notifications
            .AsNoTracking()
            .CountAsync(notification => notification.RecipientUserId == currentUserId && !notification.IsRead, cancellationToken);

        return new NotificationListDto
        {
            UnreadCount = unreadCount,
            TotalCount = totalCount,
            Page = safePage,
            PageSize = safePageSize,
            HasMore = (safePage * safePageSize) < totalCount,
            Items = items
        };
    }

    public async Task<MarkNotificationResult> MarkAsReadAsync(string currentUserId, long notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await _applicationDbContext.Notifications
            .SingleOrDefaultAsync(item => item.Id == notificationId && item.RecipientUserId == currentUserId, cancellationToken);

        if (notification == null)
        {
            return new MarkNotificationResult { NotFound = true };
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAtUtc = DateTime.UtcNow;
            await _applicationDbContext.SaveChangesAsync(cancellationToken);
            await _realtimePublisher.PublishChangedAsync(new[] { currentUserId });
        }

        return new MarkNotificationResult();
    }

    private static string MapCategory(string type)
    {
        if (type.Contains("Billing", StringComparison.OrdinalIgnoreCase)
            || type.Contains("Payment", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Billing.ToString();
        }

        if (type.Contains("Document", StringComparison.OrdinalIgnoreCase) || type.Contains("File", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Document.ToString();
        }

        if (type.Contains("Conversation", StringComparison.OrdinalIgnoreCase) || type.Contains("Message", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Conversation.ToString();
        }

        if (type.Contains("Case", StringComparison.OrdinalIgnoreCase) || type.Contains("Siting", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Case.ToString();
        }

        return NotificationCategoryFilter.System.ToString();
    }
}
