using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Contender
{
    public int Id { get; set; }

    public string Full_Name { get; set; } = null!;

    public int SSN { get; set; }

    public DateOnly BirthDate { get; set; }

    public bool? Type { get; set; }

    public virtual ICollection<Cases_Contender> Cases_Contenders { get; set; } = new List<Cases_Contender>();

    public virtual ICollection<Contenders_Custmor> Contenders_Custmors { get; set; } = new List<Contenders_Custmor>();

    public virtual ICollection<Contenders_Lawyer> Contenders_Lawyers { get; set; } = new List<Contenders_Lawyer>();
}
