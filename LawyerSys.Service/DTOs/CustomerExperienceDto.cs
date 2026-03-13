using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class CustomerRequestedDocumentDto
{
    public long Id { get; set; }
    public int CaseCode { get; set; }
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateOnly? DueDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string RequestedByName { get; set; } = string.Empty;
    public string CustomerNotes { get; set; } = string.Empty;
    public string ReviewNotes { get; set; } = string.Empty;
    public int? UploadedFileId { get; set; }
    public string UploadedFileCode { get; set; } = string.Empty;
    public string UploadedFilePath { get; set; } = string.Empty;
    public DateTime RequestedAtUtc { get; set; }
    public DateTime? SubmittedAtUtc { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
}

public class CreateCustomerRequestedDocumentRequest
{
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string Description { get; set; } = string.Empty;

    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }

    public DateOnly? DueDate { get; set; }
}

public class ReviewCustomerRequestedDocumentRequest
{
    [Required]
    [RegularExpression("Approved|Rejected")]
    public string Status { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string ReviewNotes { get; set; } = string.Empty;
}

public class CustomerPaymentProofDto
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
    public int? CaseCode { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public double Amount { get; set; }
    public DateOnly PaymentDate { get; set; }
    public string Notes { get; set; } = string.Empty;
    public int? ProofFileId { get; set; }
    public string ProofFileCode { get; set; } = string.Empty;
    public string ProofFilePath { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int? BillingPaymentId { get; set; }
    public string ReviewNotes { get; set; } = string.Empty;
    public DateTime SubmittedAtUtc { get; set; }
    public DateTime? ReviewedAtUtc { get; set; }
}

public class ReviewCustomerPaymentProofRequest
{
    [Required]
    [RegularExpression("Approved|Rejected")]
    public string Status { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string ReviewNotes { get; set; } = string.Empty;
}

public class CustomerCaseNotificationPreferenceDto
{
    public int CaseCode { get; set; }
    public bool NotificationsEnabled { get; set; }
}

public class UpdateCustomerCaseNotificationPreferenceRequest
{
    public bool NotificationsEnabled { get; set; }
}

public class UserNotificationPreferenceDto
{
    public bool CaseUpdatesEnabled { get; set; } = true;
    public bool BillingUpdatesEnabled { get; set; } = true;
    public bool DocumentRequestsEnabled { get; set; } = true;
    public bool ConversationUpdatesEnabled { get; set; } = true;
    public bool EmailNotificationsEnabled { get; set; }
    public bool SmsNotificationsEnabled { get; set; }
    public string PreferredLanguage { get; set; } = "en";
}
