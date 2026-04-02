namespace LawyerSys.DTOs;

public class SubscriptionPackageCycleOptionDto
{
    public int SubscriptionPackageId { get; set; }
    public string BillingCycle { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Currency { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class SubscriptionPackagePublicGroupDto
{
    public string OfficeSize { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public IReadOnlyList<string> Features { get; set; } = Array.Empty<string>();
    public SubscriptionPackageCycleOptionDto? MonthlyOption { get; set; }
    public SubscriptionPackageCycleOptionDto? AnnualOption { get; set; }
    public int DisplayOrder { get; set; }
}

public class SubscriptionPackageAdminGroupDto : SaveSubscriptionPackageGroupRequest
{
    public string OfficeSize { get; set; } = string.Empty;
    public int? MonthlyPackageId { get; set; }
    public int? AnnualPackageId { get; set; }
}

public class SaveSubscriptionPackageGroupRequest
{
    public string Name { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string DescriptionAr { get; set; } = string.Empty;
    public string Feature1 { get; set; } = string.Empty;
    public string Feature1Ar { get; set; } = string.Empty;
    public string Feature2 { get; set; } = string.Empty;
    public string Feature2Ar { get; set; } = string.Empty;
    public string Feature3 { get; set; } = string.Empty;
    public string Feature3Ar { get; set; } = string.Empty;
    public decimal MonthlyPrice { get; set; }
    public decimal AnnualPrice { get; set; }
    public string Currency { get; set; } = "SAR";
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
}
