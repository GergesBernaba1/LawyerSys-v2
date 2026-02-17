using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CaseStatusHistory
{
    public int Id { get; set; }
    public int Case_Id { get; set; }
    public int OldStatus { get; set; }
    public int NewStatus { get; set; }
    public string? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; }

    public virtual Case? Case { get; set; }
}