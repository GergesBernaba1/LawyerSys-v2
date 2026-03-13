using LawyerSys.Services.Email;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace LawyerSys.Services.Notifications;

public class NotificationChannelDispatcher : INotificationChannelDispatcher
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IEmailSender _emailSender;
    private readonly IExternalMessageSender _externalMessageSender;

    public NotificationChannelDispatcher(
        ApplicationDbContext applicationDbContext,
        IEmailSender emailSender,
        IExternalMessageSender externalMessageSender)
    {
        _applicationDbContext = applicationDbContext;
        _emailSender = emailSender;
        _externalMessageSender = externalMessageSender;
    }

    public async Task DispatchAsync(
        IEnumerable<string> recipientUserIds,
        string type,
        string title,
        string titleAr,
        string message,
        string messageAr,
        string? route,
        CancellationToken cancellationToken = default)
    {
        var ids = recipientUserIds
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (ids.Length == 0)
        {
            return;
        }

        var recipients = await (
            from user in _applicationDbContext.Users.AsNoTracking()
            join pref in _applicationDbContext.UserNotificationPreferences.AsNoTracking()
                on user.Id equals pref.UserId into prefJoin
            from pref in prefJoin.DefaultIfEmpty()
            where ids.Contains(user.Id)
            select new
            {
                user.Id,
                user.Email,
                user.PhoneNumber,
                user.FullName,
                user.UserName,
                Preference = pref
            }).ToListAsync(cancellationToken);

        foreach (var recipient in recipients)
        {
            var preference = recipient.Preference;
            if (preference == null)
            {
                continue;
            }

            var useArabic = string.Equals(preference.PreferredLanguage, "ar", StringComparison.OrdinalIgnoreCase);
            var localizedTitle = useArabic && !string.IsNullOrWhiteSpace(titleAr) ? titleAr : title;
            var localizedMessage = useArabic && !string.IsNullOrWhiteSpace(messageAr) ? messageAr : message;

            if (preference.EmailNotificationsEnabled && !string.IsNullOrWhiteSpace(recipient.Email))
            {
                try
                {
                    await _emailSender.SendEmailAsync(
                        recipient.Email!,
                        localizedTitle,
                        BuildEmailBody(
                            recipient.FullName ?? recipient.UserName ?? recipient.Email ?? "Customer",
                            localizedTitle,
                            localizedMessage,
                            route));
                }
                catch (Exception ex)
                {
                    Log.Warning(ex, "Failed to send customer email notification {Type} to {RecipientUserId}", type, recipient.Id);
                }
            }

            if (preference.SmsNotificationsEnabled && !string.IsNullOrWhiteSpace(recipient.PhoneNumber))
            {
                try
                {
                    await _externalMessageSender.SendSmsAsync(
                        recipient.PhoneNumber!,
                        BuildSmsBody(localizedTitle, localizedMessage),
                        cancellationToken);
                }
                catch (Exception ex)
                {
                    Log.Warning(ex, "Failed to send customer SMS notification {Type} to {RecipientUserId}", type, recipient.Id);
                }
            }
        }
    }

    private static string BuildEmailBody(string recipientName, string title, string message, string? route)
    {
        var actionLine = string.IsNullOrWhiteSpace(route)
            ? "Open the client portal to review the update."
            : $"Open the client portal and go to <strong>{System.Net.WebUtility.HtmlEncode(route)}</strong> to review the update.";

        return $"""
<div style="font-family:Segoe UI,Arial,sans-serif;background:#f5f7fb;padding:24px;">
  <div style="max-width:640px;margin:0 auto;background:#ffffff;border:1px solid #d9e2ef;border-radius:16px;overflow:hidden;">
    <div style="background:#173764;color:#ffffff;padding:20px 24px;">
      <div style="font-size:13px;letter-spacing:.08em;text-transform:uppercase;opacity:.85;">Qadaya Client Update</div>
      <div style="font-size:24px;font-weight:700;margin-top:6px;">{System.Net.WebUtility.HtmlEncode(title)}</div>
    </div>
    <div style="padding:24px;color:#1f2937;line-height:1.7;">
      <p style="margin-top:0;">Hello {System.Net.WebUtility.HtmlEncode(recipientName)},</p>
      <p>{System.Net.WebUtility.HtmlEncode(message)}</p>
      <p>{actionLine}</p>
    </div>
  </div>
</div>
""";
    }

    private static string BuildSmsBody(string title, string message)
    {
        var body = $"{title}: {message}";
        return body.Length <= 320 ? body : $"{body[..317]}...";
    }
}
