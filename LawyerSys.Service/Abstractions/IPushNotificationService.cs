namespace LawyerSys.Services.Notifications;

public interface IPushNotificationService
{
    Task SendAsync(
        IEnumerable<string> deviceTokens,
        string title,
        string body,
        string? route = null,
        IDictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
}
