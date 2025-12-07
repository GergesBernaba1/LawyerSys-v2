using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Con_Lawyers_Custmor
{
    public int Id { get; set; }

    public int Con_Custmor_Id { get; set; }

    public int Con_Lawyer_Id { get; set; }

    public virtual Contenders_Lawyer Con_Lawyer { get; set; } = null!;
}
