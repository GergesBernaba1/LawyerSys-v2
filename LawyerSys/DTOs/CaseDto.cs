namespace LawyerSys.DTOs;

public class CaseDto
{
    public int Id { get; set; }
    public int Code { get; set; }
    public string InvitionsStatment { get; set; } = string.Empty;
    public string InvitionType { get; set; } = string.Empty;
    public DateOnly InvitionDate { get; set; }
    public int TotalAmount { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public class CreateCaseDto
{
    public int Code { get; set; }
    public string InvitionsStatment { get; set; } = string.Empty;
    public string InvitionType { get; set; } = string.Empty;
    public DateOnly InvitionDate { get; set; }
    public int TotalAmount { get; set; }
    public string? Notes { get; set; }
}

public class UpdateCaseDto
{
    public string? InvitionsStatment { get; set; }
    public string? InvitionType { get; set; }
    public DateOnly? InvitionDate { get; set; }
    public int? TotalAmount { get; set; }
    public string? Notes { get; set; }
}
