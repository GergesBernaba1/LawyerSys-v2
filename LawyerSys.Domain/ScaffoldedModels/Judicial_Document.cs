using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Judicial_Document
{
    public int Id { get; set; }

    public string Doc_Type { get; set; } = null!;

    public int Doc_Num { get; set; }

    public string Doc_Details { get; set; } = null!;

    public string Notes { get; set; } = null!;

    public int Num_Of_Agent { get; set; }

    public int Customers_Id { get; set; }

    public virtual Customer Customers { get; set; } = null!;
}
