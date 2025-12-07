namespace LawyerSys.DTOs;

// Billing Pay DTOs
public class BillingPayDto
{
    public int Id { get; set; }
    public double Amount { get; set; }
    public DateOnly DateOfOperation { get; set; }
    public string Notes { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public string? CustomerName { get; set; }
}

public class CreateBillingPayDto
{
    public double Amount { get; set; }
    public DateOnly DateOfOperation { get; set; }
    public string? Notes { get; set; }
    public int CustomerId { get; set; }
}

public class UpdateBillingPayDto
{
    public double? Amount { get; set; }
    public DateOnly? DateOfOperation { get; set; }
    public string? Notes { get; set; }
}

// Billing Receipt DTOs
public class BillingReceiptDto
{
    public int Id { get; set; }
    public double Amount { get; set; }
    public DateOnly DateOfOperation { get; set; }
    public string Notes { get; set; } = string.Empty;
    public int EmployeeId { get; set; }
}

public class CreateBillingReceiptDto
{
    public double Amount { get; set; }
    public DateOnly DateOfOperation { get; set; }
    public string? Notes { get; set; }
    public int EmployeeId { get; set; }
}

public class UpdateBillingReceiptDto
{
    public double? Amount { get; set; }
    public DateOnly? DateOfOperation { get; set; }
    public string? Notes { get; set; }
}
