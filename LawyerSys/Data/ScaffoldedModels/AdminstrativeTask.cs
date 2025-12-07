using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class AdminstrativeTask
{
    public int Id { get; set; }

    public string Task_Name { get; set; } = null!;

    public string Type { get; set; } = null!;

    public DateOnly Task_Date { get; set; }

    public DateTime Task_Reminder_Date { get; set; }

    public string Notes { get; set; } = null!;

    public int? employee_Id { get; set; }

    public virtual Employee? employee { get; set; }
}
