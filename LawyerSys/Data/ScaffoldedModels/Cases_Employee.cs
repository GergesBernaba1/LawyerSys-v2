using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Cases_Employee
{
    public int Id { get; set; }

    public int Case_Code { get; set; }

    public int Employee_Id { get; set; }

    public virtual Employee Employee { get; set; } = null!;
}
