using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Consulation
{
    public int Id { get; set; }

    public string Consultion_State { get; set; } = null!;

    public string Type { get; set; } = null!;

    public string Subject { get; set; } = null!;

    public string Descraption { get; set; } = null!;

    public string Feedback { get; set; } = null!;

    public string Notes { get; set; } = null!;

    public DateTime Date_time { get; set; }

    public virtual ICollection<Consltitions_Custmor> Consltitions_Custmors { get; set; } = new List<Consltitions_Custmor>();
}
