using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Custmors_Case
{
    public int Id { get; set; }

    public int Case_Id { get; set; }

    public int Custmors_Id { get; set; }

    public virtual Case Case { get; set; } = null!;

    public virtual Customer Custmors { get; set; } = null!;
}
