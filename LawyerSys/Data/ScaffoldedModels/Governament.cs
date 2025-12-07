using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Governament
{
    public int Id { get; set; }

    public string Gov_Name { get; set; } = null!;

    public virtual ICollection<Court> Courts { get; set; } = new List<Court>();
}
