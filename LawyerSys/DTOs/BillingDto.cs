using System.ComponentModel.DataAnnotations;

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
    [Range(0.01, double.MaxValue)]
    public double Amount { get; set; }

    [Required]
    public DateOnly DateOfOperation { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
    public int CustomerId { get; set; }
}

public class UpdateBillingPayDto
{
    [Range(0.01, double.MaxValue)]
    public double? Amount { get; set; }
    public DateOnly? DateOfOperation { get; set; }

    [MaxLength(2000)]
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
    [Range(0.01, double.MaxValue)]
    public double Amount { get; set; }

    [Required]
    public DateOnly DateOfOperation { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }

    [Range(1, int.MaxValue)]
    public int EmployeeId { get; set; }
}

public class UpdateBillingReceiptDto
{
    [Range(0.01, double.MaxValue)]
    public double? Amount { get; set; }
    public DateOnly? DateOfOperation { get; set; }

    [MaxLength(2000)]
    public string? Notes { get; set; }
}
