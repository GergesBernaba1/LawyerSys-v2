using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class CaseConversationMessageDto
{
    public long Id { get; set; }
    public int CaseCode { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string SenderRole { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool VisibleToCustomer { get; set; }
    public int? AttachmentFileId { get; set; }
    public string AttachmentFileCode { get; set; } = string.Empty;
    public string AttachmentFilePath { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? ReadByCustomerAtUtc { get; set; }
    public DateTime? ReadByOfficeAtUtc { get; set; }
    public bool IsMine { get; set; }
    public bool IsReadByOtherParty { get; set; }
}

public class CreateCaseConversationMessageRequest
{
    [Required]
    [MaxLength(4000)]
    public string Message { get; set; } = string.Empty;

    public bool VisibleToCustomer { get; set; } = true;
}
