namespace LawyerSys.Services.Notifications;

public interface IExternalMessageSender
{
    Task<bool> SendWhatsAppAsync(string to, string message, CancellationToken cancellationToken = default);
    Task<bool> SendSmsAsync(string to, string message, CancellationToken cancellationToken = default);
}
