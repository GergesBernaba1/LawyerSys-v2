using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.SignalR;

namespace LawyerSys.Realtime;

public class SignalRNotificationRealtimePublisher : INotificationRealtimePublisher
{
    private readonly IHubContext<NotificationHub> _notificationHub;

    public SignalRNotificationRealtimePublisher(IHubContext<NotificationHub> notificationHub)
    {
        _notificationHub = notificationHub;
    }

    public Task PublishChangedAsync(IEnumerable<string> userIds, CancellationToken cancellationToken = default)
    {
        var ids = userIds
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (ids.Length == 0)
        {
            return Task.CompletedTask;
        }

        return _notificationHub.Clients.Users(ids).SendAsync("NotificationsChanged", cancellationToken);
    }
}
