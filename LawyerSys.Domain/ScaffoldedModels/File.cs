using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class File
{
    public int Id { get; set; }

    public string? Path { get; set; }

    public string? Code { get; set; }

    public bool? type { get; set; }

    public virtual ICollection<Cases_File> Cases_Files { get; set; } = new List<Cases_File>();
}
