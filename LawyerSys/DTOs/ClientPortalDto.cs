namespace LawyerSys.DTOs;

public class ClientPortalCaseDto
{
    public int Code { get; set; }
    public string Type { get; set; } = string.Empty;
    public DateOnly Date { get; set; }
    public int TotalAmount { get; set; }
    public int Status { get; set; }
}

public class ClientPortalHearingDto
{
    public int CaseCode { get; set; }
    public DateOnly Date { get; set; }
    public DateTime Time { get; set; }
    public string JudgeName { get; set; } = string.Empty;
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

public class ClientPortalResponseDto
{
    public string CustomerName { get; set; } = string.Empty;
    public IEnumerable<ClientPortalCaseDto> Cases { get; set; } = Array.Empty<ClientPortalCaseDto>();
    public IEnumerable<ClientPortalHearingDto> Hearings { get; set; } = Array.Empty<ClientPortalHearingDto>();
    public IEnumerable<ClientPortalDocumentDto> Documents { get; set; } = Array.Empty<ClientPortalDocumentDto>();
    public ClientPortalBillingDto Billing { get; set; } = new();
}
