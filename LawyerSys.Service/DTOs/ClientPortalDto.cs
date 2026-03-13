namespace LawyerSys.DTOs;

public class ClientPortalCaseDto
{
    public int Code { get; set; }
    public string Type { get; set; } = string.Empty;
    public DateOnly Date { get; set; }
    public int TotalAmount { get; set; }
    public int Status { get; set; }
    public string LatestUpdate { get; set; } = string.Empty;
}

public class ClientPortalHearingDto
{
    public int CaseCode { get; set; }
    public DateOnly Date { get; set; }
    public DateTime Time { get; set; }
    public string JudgeName { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
}

public class ClientPortalDocumentDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public int Number { get; set; }
    public string Details { get; set; } = string.Empty;
}

public class ClientPortalBillingDto
{
    public double TotalPayments { get; set; }
    public double CasesTotalAmount { get; set; }
    public double OutstandingBalance { get; set; }
}

public class ClientPortalPaymentDto
{
    public int Id { get; set; }
    public DateOnly Date { get; set; }
    public double Amount { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public class ClientPortalCaseFileDto
{
    public int FileId { get; set; }
    public int CaseCode { get; set; }
    public string FileCode { get; set; } = string.Empty;
    public string FilePath { get; set; } = string.Empty;
}

public class ClientPortalSummaryDto
{
    public int ActiveCasesCount { get; set; }
    public int PendingRequestedDocumentsCount { get; set; }
    public int UnreadMessagesCount { get; set; }
    public int UpcomingSessionsCount { get; set; }
    public int PendingPaymentProofsCount { get; set; }
    public DateTime? NextSessionAtUtc { get; set; }
    public string NextSessionLabel { get; set; } = string.Empty;
}

public class ClientPortalRecentUpdateDto
{
    public long Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class ClientPortalConversationThreadDto
{
    public int CaseCode { get; set; }
    public string CaseType { get; set; } = string.Empty;
    public string LastMessage { get; set; } = string.Empty;
    public string LastSenderName { get; set; } = string.Empty;
    public string LastSenderRole { get; set; } = string.Empty;
    public DateTime? LastMessageAtUtc { get; set; }
    public int UnreadCount { get; set; }
    public bool WaitingOnCustomer { get; set; }
    public bool HasAttachment { get; set; }
}

public class ClientPortalContactDto
{
    public int EmployeeId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string JobTitle { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
}

public class ClientPortalResponseDto
{
    public string CustomerName { get; set; } = string.Empty;
    public IEnumerable<ClientPortalCaseDto> Cases { get; set; } = Array.Empty<ClientPortalCaseDto>();
    public IEnumerable<ClientPortalHearingDto> Hearings { get; set; } = Array.Empty<ClientPortalHearingDto>();
    public IEnumerable<ClientPortalDocumentDto> Documents { get; set; } = Array.Empty<ClientPortalDocumentDto>();
    public IEnumerable<ClientPortalPaymentDto> Payments { get; set; } = Array.Empty<ClientPortalPaymentDto>();
    public IEnumerable<ClientPortalCaseFileDto> CaseFiles { get; set; } = Array.Empty<ClientPortalCaseFileDto>();
    public IEnumerable<CustomerRequestedDocumentDto> RequestedDocuments { get; set; } = Array.Empty<CustomerRequestedDocumentDto>();
    public IEnumerable<CustomerPaymentProofDto> PaymentProofs { get; set; } = Array.Empty<CustomerPaymentProofDto>();
    public IEnumerable<ClientPortalRecentUpdateDto> RecentUpdates { get; set; } = Array.Empty<ClientPortalRecentUpdateDto>();
    public IEnumerable<ClientPortalConversationThreadDto> ConversationThreads { get; set; } = Array.Empty<ClientPortalConversationThreadDto>();
    public IEnumerable<ClientPortalContactDto> OfficeContacts { get; set; } = Array.Empty<ClientPortalContactDto>();
    public ClientPortalBillingDto Billing { get; set; } = new();
    public ClientPortalSummaryDto Summary { get; set; } = new();
}
