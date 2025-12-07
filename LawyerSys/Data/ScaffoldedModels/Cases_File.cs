using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Cases_File
{
    public int Id { get; set; }

    public int Case_Id { get; set; }

    public int File_Id { get; set; }

    public virtual Case Case { get; set; } = null!;

    public virtual File File { get; set; } = null!;
}
