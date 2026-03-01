using System.Collections.Generic;

namespace LawyerSys.Data.ScaffoldedModels;

public partial class CourtAutomationPack
{
    public int Id { get; set; }

    public string Key { get; set; } = null!;

    public string NameEn { get; set; } = null!;

    public string NameAr { get; set; } = null!;

    public string DescriptionEn { get; set; } = null!;

    public string DescriptionAr { get; set; } = null!;

    public string JurisdictionCode { get; set; } = null!;

    public bool IsActive { get; set; } = true;

    public virtual ICollection<CourtAutomationFormTemplate> FormTemplates { get; set; } = new List<CourtAutomationFormTemplate>();

    public virtual ICollection<CourtAutomationDeadlineRule> DeadlineRules { get; set; } = new List<CourtAutomationDeadlineRule>();

    public virtual ICollection<CourtAutomationFilingChannel> FilingChannels { get; set; } = new List<CourtAutomationFilingChannel>();
}
