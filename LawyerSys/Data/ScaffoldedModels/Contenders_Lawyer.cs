using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Contenders_Lawyer
{
    public int Id { get; set; }

    public int Contender_Id { get; set; }

    public virtual ICollection<Con_Lawyers_Custmor> Con_Lawyers_Custmors { get; set; } = new List<Con_Lawyers_Custmor>();

    public virtual Contender Contender { get; set; } = null!;

    public virtual ICollection<Contenders_Custmor> Contenders_Custmors { get; set; } = new List<Contenders_Custmor>();
}
