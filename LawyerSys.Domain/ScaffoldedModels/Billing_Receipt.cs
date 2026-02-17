using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Billing_Receipt
{
    public int Id { get; set; }

    public double Amount { get; set; }

    public DateOnly Date_Of_Opreation { get; set; }

    public string Notes { get; set; } = null!;

    public int Employee_Id { get; set; }

    public virtual Customer Employee { get; set; } = null!;
}
