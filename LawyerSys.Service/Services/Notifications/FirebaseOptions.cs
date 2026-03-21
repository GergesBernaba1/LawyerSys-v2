namespace LawyerSys.Services.Notifications;

public class FirebaseOptions
{
    public bool Enabled { get; set; }
    public string ServiceAccountKeyPath { get; set; } = string.Empty;
    public string? ProjectId { get; set; }
    public string? DefaultNotificationIcon { get; set; }
}
