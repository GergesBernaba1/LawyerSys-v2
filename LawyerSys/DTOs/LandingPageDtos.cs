namespace LawyerSys.DTOs;

public class LandingPagePublicDto
{
    public string SystemName { get; set; } = string.Empty;
    public string Tagline { get; set; } = string.Empty;
    public string HeroTitle { get; set; } = string.Empty;
    public string HeroSubtitle { get; set; } = string.Empty;
    public string PrimaryButtonText { get; set; } = string.Empty;
    public string PrimaryButtonUrl { get; set; } = string.Empty;
    public string SecondaryButtonText { get; set; } = string.Empty;
    public string SecondaryButtonUrl { get; set; } = string.Empty;
    public string AboutTitle { get; set; } = string.Empty;
    public string AboutDescription { get; set; } = string.Empty;
    public string AboutPageTitle { get; set; } = string.Empty;
    public string AboutPageSubtitle { get; set; } = string.Empty;
    public string AboutPageDescription { get; set; } = string.Empty;
    public string AboutPageMissionTitle { get; set; } = string.Empty;
    public string AboutPageMissionDescription { get; set; } = string.Empty;
    public string AboutPageVisionTitle { get; set; } = string.Empty;
    public string AboutPageVisionDescription { get; set; } = string.Empty;
    public string ContactPageTitle { get; set; } = string.Empty;
    public string ContactPageSubtitle { get; set; } = string.Empty;
    public string ContactPageDescription { get; set; } = string.Empty;
    public string ContactAddress { get; set; } = string.Empty;
    public string ContactWorkingHours { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;
    public IReadOnlyList<LandingPageFeatureDto> Features { get; set; } = Array.Empty<LandingPageFeatureDto>();
}

public class LandingPageFeatureDto
{
    public string IconKey { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class LandingPageAdminDto : UpdateLandingPageRequest
{
    public DateTime UpdatedAtUtc { get; set; }
}

public class UpdateLandingPageRequest
{
    public string SystemName { get; set; } = string.Empty;
    public string SystemNameAr { get; set; } = string.Empty;
    public string Tagline { get; set; } = string.Empty;
    public string TaglineAr { get; set; } = string.Empty;
    public string HeroTitle { get; set; } = string.Empty;
    public string HeroTitleAr { get; set; } = string.Empty;
    public string HeroSubtitle { get; set; } = string.Empty;
    public string HeroSubtitleAr { get; set; } = string.Empty;
    public string PrimaryButtonText { get; set; } = string.Empty;
    public string PrimaryButtonTextAr { get; set; } = string.Empty;
    public string PrimaryButtonUrl { get; set; } = string.Empty;
    public string SecondaryButtonText { get; set; } = string.Empty;
    public string SecondaryButtonTextAr { get; set; } = string.Empty;
    public string SecondaryButtonUrl { get; set; } = string.Empty;
    public string AboutTitle { get; set; } = string.Empty;
    public string AboutTitleAr { get; set; } = string.Empty;
    public string AboutDescription { get; set; } = string.Empty;
    public string AboutDescriptionAr { get; set; } = string.Empty;
    public string AboutPageTitle { get; set; } = string.Empty;
    public string AboutPageTitleAr { get; set; } = string.Empty;
    public string AboutPageSubtitle { get; set; } = string.Empty;
    public string AboutPageSubtitleAr { get; set; } = string.Empty;
    public string AboutPageDescription { get; set; } = string.Empty;
    public string AboutPageDescriptionAr { get; set; } = string.Empty;
    public string AboutPageMissionTitle { get; set; } = string.Empty;
    public string AboutPageMissionTitleAr { get; set; } = string.Empty;
    public string AboutPageMissionDescription { get; set; } = string.Empty;
    public string AboutPageMissionDescriptionAr { get; set; } = string.Empty;
    public string AboutPageVisionTitle { get; set; } = string.Empty;
    public string AboutPageVisionTitleAr { get; set; } = string.Empty;
    public string AboutPageVisionDescription { get; set; } = string.Empty;
    public string AboutPageVisionDescriptionAr { get; set; } = string.Empty;
    public string Feature1Title { get; set; } = string.Empty;
    public string Feature1TitleAr { get; set; } = string.Empty;
    public string Feature1Description { get; set; } = string.Empty;
    public string Feature1DescriptionAr { get; set; } = string.Empty;
    public string Feature2Title { get; set; } = string.Empty;
    public string Feature2TitleAr { get; set; } = string.Empty;
    public string Feature2Description { get; set; } = string.Empty;
    public string Feature2DescriptionAr { get; set; } = string.Empty;
    public string Feature3Title { get; set; } = string.Empty;
    public string Feature3TitleAr { get; set; } = string.Empty;
    public string Feature3Description { get; set; } = string.Empty;
    public string Feature3DescriptionAr { get; set; } = string.Empty;
    public string ContactPageTitle { get; set; } = string.Empty;
    public string ContactPageTitleAr { get; set; } = string.Empty;
    public string ContactPageSubtitle { get; set; } = string.Empty;
    public string ContactPageSubtitleAr { get; set; } = string.Empty;
    public string ContactPageDescription { get; set; } = string.Empty;
    public string ContactPageDescriptionAr { get; set; } = string.Empty;
    public string ContactAddress { get; set; } = string.Empty;
    public string ContactAddressAr { get; set; } = string.Empty;
    public string ContactWorkingHours { get; set; } = string.Empty;
    public string ContactWorkingHoursAr { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;
}
