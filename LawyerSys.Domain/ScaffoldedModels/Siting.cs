using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Siting
{
    public int Id { get; set; }

    public DateTime Siting_Time { get; set; }

    public DateOnly Siting_Date { get; set; }

    public DateTime Siting_Notification { get; set; }

    public string Judge_Name { get; set; } = null!;

    public string Notes { get; set; } = null!;

    public virtual ICollection<Cases_Siting> Cases_Sitings { get; set; } = new List<Cases_Siting>();
}
