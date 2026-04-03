using System;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CaseCourtHistory
{
    public int Id { get; set; }
    public int Case_Id { get; set; }
    public int? OldCourt_Id { get; set; }
    public int? NewCourt_Id { get; set; }
    public string? OldCourt_Name { get; set; }
    public string? NewCourt_Name { get; set; }
    public string ChangeType { get; set; } = null!;
    public string? ChangedBy { get; set; }
    public DateTime ChangedAt { get; set; }

    public virtual Case? Case { get; set; }
    public virtual Court? OldCourt { get; set; }
    public virtual Court? NewCourt { get; set; }
}
