using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Contenders_Custmor
{
    public int Id { get; set; }

    public int? Con_Lawyer_ID { get; set; }

    public int? Con_Id { get; set; }

    public virtual Contender? Con { get; set; }

    public virtual Contenders_Lawyer? Con_Lawyer { get; set; }
}
