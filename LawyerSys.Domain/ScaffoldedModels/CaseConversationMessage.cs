using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CaseConversationMessage
{
    public long Id { get; set; }
    public int CaseCode { get; set; }
    public string SenderUserId { get; set; } = string.Empty;
    public string SenderName { get; set; } = string.Empty;
    public string SenderRole { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool VisibleToCustomer { get; set; } = true;
    public int? AttachmentFileId { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ReadByCustomerAtUtc { get; set; }
    public DateTime? ReadByOfficeAtUtc { get; set; }
    public int FirmId { get; set; }
}
