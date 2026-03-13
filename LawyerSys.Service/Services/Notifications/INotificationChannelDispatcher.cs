namespace LawyerSys.Services.Notifications;

public interface INotificationChannelDispatcher
{
    Task DispatchAsync(
        IEnumerable<string> recipientUserIds,
        string type,
        string title,
        string titleAr,
        string message,
        string messageAr,
        string? route,
        CancellationToken cancellationToken = default);
}
