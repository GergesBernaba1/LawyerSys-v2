using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Cases_Court
{
    public int Id { get; set; }

    public int Court_Id { get; set; }

    public int Case_Code { get; set; }

    public virtual Case Case_CodeNavigation { get; set; } = null!;

    public virtual Court Court { get; set; } = null!;
}
