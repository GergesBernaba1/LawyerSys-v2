using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Court
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Address { get; set; } = null!;

    public string Telephone { get; set; } = null!;

    public string Notes { get; set; } = null!;

    public int Gov_Id { get; set; }

    public virtual ICollection<Cases_Court> Cases_Courts { get; set; } = new List<Cases_Court>();

    public virtual Governament Gov { get; set; } = null!;
}
