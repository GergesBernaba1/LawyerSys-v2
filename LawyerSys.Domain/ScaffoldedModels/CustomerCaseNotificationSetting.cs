using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CustomerCaseNotificationSetting
{
    public long Id { get; set; }
    public int CaseCode { get; set; }
    public int CustomerId { get; set; }
    public bool NotificationsEnabled { get; set; } = true;
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    public int FirmId { get; set; }
}
