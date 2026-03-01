namespace LawyerSys.Data.ScaffoldedModels;

public partial class CourtAutomationDeadlineRule
{
    public int Id { get; set; }

    public int PackId { get; set; }

    public string Key { get; set; } = null!;

    public string NameEn { get; set; } = null!;

    public string NameAr { get; set; } = null!;

    public string DescriptionEn { get; set; } = null!;

    public string DescriptionAr { get; set; } = null!;

    public int OffsetDays { get; set; }

    public string Anchor { get; set; } = null!;

    public bool IsActive { get; set; } = true;

    public virtual CourtAutomationPack Pack { get; set; } = null!;
}
