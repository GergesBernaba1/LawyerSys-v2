using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Consltitions_Custmor
{
    public int Id { get; set; }

    public int Customer_Id { get; set; }

    public int Consl_Id { get; set; }

    public virtual Consulation Consl { get; set; } = null!;

    public virtual Customer Customer { get; set; } = null!;
}
