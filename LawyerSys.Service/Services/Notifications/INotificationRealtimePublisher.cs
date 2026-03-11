namespace LawyerSys.Services.Notifications;

public interface INotificationRealtimePublisher
{
    Task PublishChangedAsync(IEnumerable<string> userIds, CancellationToken cancellationToken = default);
}
