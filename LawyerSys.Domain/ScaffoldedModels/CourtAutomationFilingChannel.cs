namespace LawyerSys.Data.ScaffoldedModels;

public partial class CourtAutomationFilingChannel
{
    public int Id { get; set; }

    public int PackId { get; set; }

    public string ChannelCode { get; set; } = null!;

    public string DisplayNameEn { get; set; } = null!;

    public string DisplayNameAr { get; set; } = null!;

    public bool IsActive { get; set; } = true;

    public virtual CourtAutomationPack Pack { get; set; } = null!;
}
