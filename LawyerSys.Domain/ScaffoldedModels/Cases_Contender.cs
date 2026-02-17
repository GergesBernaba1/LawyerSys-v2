using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Cases_Contender
{
    public int Id { get; set; }

    public int Case_Id { get; set; }

    public int Contender_Id { get; set; }

    public virtual Case Case { get; set; } = null!;

    public virtual Contender Contender { get; set; } = null!;
}
