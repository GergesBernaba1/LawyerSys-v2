using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Billing_Pay
{
    public int Id { get; set; }

    public double Amount { get; set; }

    public DateOnly Date_Of_Opreation { get; set; }

    public string Notes { get; set; } = null!;

    public int Custmor_Id { get; set; }

    public virtual Customer Custmor { get; set; } = null!;
}
