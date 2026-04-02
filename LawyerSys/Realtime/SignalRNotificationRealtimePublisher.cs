using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;

namespace LawyerSys.Realtime;

public class SignalRNotificationRealtimePublisher : INotificationRealtimePublisher
{
    private readonly IHubContext<NotificationHub> _notificationHub;
    private readonly ILogger<SignalRNotificationRealtimePublisher> _logger;

    public SignalRNotificationRealtimePublisher(
        IHubContext<NotificationHub> notificationHub,
        ILogger<SignalRNotificationRealtimePublisher> logger)
    {
        _notificationHub = notificationHub;
        _logger = logger;
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

        _logger.LogInformation(
            "Publishing NotificationsChanged to {RecipientCount} recipients",
            ids.Length);

        return _notificationHub.Clients.Users(ids).SendAsync("NotificationsChanged", cancellationToken);
    }
}
