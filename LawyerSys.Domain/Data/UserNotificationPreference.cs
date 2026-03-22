using System;

public class UserNotificationPreference
{
    public long Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public bool CaseUpdatesEnabled { get; set; } = true;
    public bool BillingUpdatesEnabled { get; set; } = true;
    public bool DocumentRequestsEnabled { get; set; } = true;
    public bool ConversationUpdatesEnabled { get; set; } = true;
    public bool EmailNotificationsEnabled { get; set; }
    public bool SmsNotificationsEnabled { get; set; }
    public bool PushNotificationsEnabled { get; set; } = true;
    public string PreferredLanguage { get; set; } = "en";
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
