using LawyerSys.DTOs;

namespace LawyerSys.Services.Notifications;

public interface INotificationsQueryService
{
    Task<NotificationListDto> GetNotificationsAsync(string currentUserId, int page, int pageSize, NotificationReadFilter filter, NotificationCategoryFilter category, CancellationToken cancellationToken = default);
    Task<MarkNotificationResult> MarkAsReadAsync(string currentUserId, long notificationId, CancellationToken cancellationToken = default);
}

public sealed class MarkNotificationResult
{
    public bool NotFound { get; init; }
}
