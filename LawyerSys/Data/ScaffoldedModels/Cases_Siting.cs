using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Cases_Siting
{
    public int Id { get; set; }

    public int Case_Code { get; set; }

    public int Siting_Id { get; set; }

    public virtual Case Case_CodeNavigation { get; set; } = null!;

    public virtual Siting Siting { get; set; } = null!;
}
