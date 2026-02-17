using System;
using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class Case
{
    public int Id { get; set; }

    public int Code { get; set; }

    public string Invitions_Statment { get; set; } = null!;

    public string Invition_Type { get; set; } = null!;

    public DateOnly Invition_Date { get; set; }

    public int Total_Amount { get; set; }

    public string Notes { get; set; } = null!;

    // Case status (stored as int): 0=New,1=InProgress,2=AwaitingHearing,3=Closed,4=Won,5=Lost
    public int Status { get; set; }

    public virtual ICollection<Cases_Contender> Cases_Contenders { get; set; } = new List<Cases_Contender>();

    public virtual ICollection<Cases_Court> Cases_Courts { get; set; } = new List<Cases_Court>();

    public virtual ICollection<Cases_File> Cases_Files { get; set; } = new List<Cases_File>();

    public virtual ICollection<Cases_Siting> Cases_Sitings { get; set; } = new List<Cases_Siting>();

    public virtual ICollection<Custmors_Case> Custmors_Cases { get; set; } = new List<Custmors_Case>();

    public virtual ICollection<CaseStatusHistory> CaseStatusHistories { get; set; } = new List<CaseStatusHistory>();
}
