namespace LawyerSys.Services.Notifications;

public class NotificationChannelsOptions
{
    public WhatsAppOptions WhatsApp { get; set; } = new();
    public SmsOptions Sms { get; set; } = new();

    public class WhatsAppOptions
    {
        public bool Enabled { get; set; }
        public string AccountSid { get; set; } = string.Empty;
        public string AuthToken { get; set; } = string.Empty;
        public string From { get; set; } = string.Empty;
    }

    public class SmsOptions
    {
        public bool Enabled { get; set; }
        public string AccountSid { get; set; } = string.Empty;
        public string AuthToken { get; set; } = string.Empty;
        public string From { get; set; } = string.Empty;
    }
}
