using System.Globalization;
using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Landing;

public sealed class LandingPageService : ILandingPageService
{
    private readonly ApplicationDbContext _applicationDbContext;

    public LandingPageService(ApplicationDbContext applicationDbContext)
    {
        _applicationDbContext = applicationDbContext;
    }

    public async Task<LandingPagePublicDto> GetLandingPageAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateSettingsAsync(cancellationToken);
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";

        return new LandingPagePublicDto
        {
            SystemName = useArabic ? GetLocalized(settings.SystemNameAr, settings.SystemName) : settings.SystemName,
            Tagline = useArabic ? GetLocalized(settings.TaglineAr, settings.Tagline) : settings.Tagline,
            HeroTitle = useArabic ? GetLocalized(settings.HeroTitleAr, settings.HeroTitle) : settings.HeroTitle,
            HeroSubtitle = useArabic ? GetLocalized(settings.HeroSubtitleAr, settings.HeroSubtitle) : settings.HeroSubtitle,
            PrimaryButtonText = useArabic ? GetLocalized(settings.PrimaryButtonTextAr, settings.PrimaryButtonText) : settings.PrimaryButtonText,
            PrimaryButtonUrl = settings.PrimaryButtonUrl,
            SecondaryButtonText = useArabic ? GetLocalized(settings.SecondaryButtonTextAr, settings.SecondaryButtonText) : settings.SecondaryButtonText,
            SecondaryButtonUrl = settings.SecondaryButtonUrl,
            AboutTitle = useArabic ? GetLocalized(settings.AboutTitleAr, settings.AboutTitle) : settings.AboutTitle,
            AboutDescription = useArabic ? GetLocalized(settings.AboutDescriptionAr, settings.AboutDescription) : settings.AboutDescription,
            AboutPageTitle = useArabic ? GetLocalized(settings.AboutPageTitleAr, settings.AboutPageTitle) : settings.AboutPageTitle,
            AboutPageSubtitle = useArabic ? GetLocalized(settings.AboutPageSubtitleAr, settings.AboutPageSubtitle) : settings.AboutPageSubtitle,
            AboutPageDescription = useArabic ? GetLocalized(settings.AboutPageDescriptionAr, settings.AboutPageDescription) : settings.AboutPageDescription,
            AboutPageMissionTitle = useArabic ? GetLocalized(settings.AboutPageMissionTitleAr, settings.AboutPageMissionTitle) : settings.AboutPageMissionTitle,
            AboutPageMissionDescription = useArabic ? GetLocalized(settings.AboutPageMissionDescriptionAr, settings.AboutPageMissionDescription) : settings.AboutPageMissionDescription,
            AboutPageVisionTitle = useArabic ? GetLocalized(settings.AboutPageVisionTitleAr, settings.AboutPageVisionTitle) : settings.AboutPageVisionTitle,
            AboutPageVisionDescription = useArabic ? GetLocalized(settings.AboutPageVisionDescriptionAr, settings.AboutPageVisionDescription) : settings.AboutPageVisionDescription,
            ContactPageTitle = useArabic ? GetLocalized(settings.ContactPageTitleAr, settings.ContactPageTitle) : settings.ContactPageTitle,
            ContactPageSubtitle = useArabic ? GetLocalized(settings.ContactPageSubtitleAr, settings.ContactPageSubtitle) : settings.ContactPageSubtitle,
            ContactPageDescription = useArabic ? GetLocalized(settings.ContactPageDescriptionAr, settings.ContactPageDescription) : settings.ContactPageDescription,
            ContactAddress = useArabic ? GetLocalized(settings.ContactAddressAr, settings.ContactAddress) : settings.ContactAddress,
            ContactWorkingHours = useArabic ? GetLocalized(settings.ContactWorkingHoursAr, settings.ContactWorkingHours) : settings.ContactWorkingHours,
            ContactEmail = settings.ContactEmail,
            ContactPhone = settings.ContactPhone,
            Features = new[]
            {
                new LandingPageFeatureDto
                {
                    IconKey = "automation",
                    Title = useArabic ? GetLocalized(settings.Feature1TitleAr, settings.Feature1Title) : settings.Feature1Title,
                    Description = useArabic ? GetLocalized(settings.Feature1DescriptionAr, settings.Feature1Description) : settings.Feature1Description,
                },
                new LandingPageFeatureDto
                {
                    IconKey = "collaboration",
                    Title = useArabic ? GetLocalized(settings.Feature2TitleAr, settings.Feature2Title) : settings.Feature2Title,
                    Description = useArabic ? GetLocalized(settings.Feature2DescriptionAr, settings.Feature2Description) : settings.Feature2Description,
                },
                new LandingPageFeatureDto
                {
                    IconKey = "insight",
                    Title = useArabic ? GetLocalized(settings.Feature3TitleAr, settings.Feature3Title) : settings.Feature3Title,
                    Description = useArabic ? GetLocalized(settings.Feature3DescriptionAr, settings.Feature3Description) : settings.Feature3Description,
                },
            }
        };
    }

    public async Task<LandingPageAdminDto> GetLandingPageAdminAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateSettingsAsync(cancellationToken);
        return MapAdmin(settings);
    }

    public async Task<LandingPageAdminDto> UpdateLandingPageAsync(UpdateLandingPageRequest request, CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateSettingsAsync(cancellationToken);
        settings.SystemName = Normalize(request.SystemName);
        settings.SystemNameAr = Normalize(request.SystemNameAr);
        settings.Tagline = Normalize(request.Tagline);
        settings.TaglineAr = Normalize(request.TaglineAr);
        settings.HeroTitle = Normalize(request.HeroTitle);
        settings.HeroTitleAr = Normalize(request.HeroTitleAr);
        settings.HeroSubtitle = Normalize(request.HeroSubtitle);
        settings.HeroSubtitleAr = Normalize(request.HeroSubtitleAr);
        settings.PrimaryButtonText = Normalize(request.PrimaryButtonText);
        settings.PrimaryButtonTextAr = Normalize(request.PrimaryButtonTextAr);
        settings.PrimaryButtonUrl = Normalize(request.PrimaryButtonUrl);
        settings.SecondaryButtonText = Normalize(request.SecondaryButtonText);
        settings.SecondaryButtonTextAr = Normalize(request.SecondaryButtonTextAr);
        settings.SecondaryButtonUrl = Normalize(request.SecondaryButtonUrl);
        settings.AboutTitle = Normalize(request.AboutTitle);
        settings.AboutTitleAr = Normalize(request.AboutTitleAr);
        settings.AboutDescription = Normalize(request.AboutDescription);
        settings.AboutDescriptionAr = Normalize(request.AboutDescriptionAr);
        settings.AboutPageTitle = Normalize(request.AboutPageTitle);
        settings.AboutPageTitleAr = Normalize(request.AboutPageTitleAr);
        settings.AboutPageSubtitle = Normalize(request.AboutPageSubtitle);
        settings.AboutPageSubtitleAr = Normalize(request.AboutPageSubtitleAr);
        settings.AboutPageDescription = Normalize(request.AboutPageDescription);
        settings.AboutPageDescriptionAr = Normalize(request.AboutPageDescriptionAr);
        settings.AboutPageMissionTitle = Normalize(request.AboutPageMissionTitle);
        settings.AboutPageMissionTitleAr = Normalize(request.AboutPageMissionTitleAr);
        settings.AboutPageMissionDescription = Normalize(request.AboutPageMissionDescription);
        settings.AboutPageMissionDescriptionAr = Normalize(request.AboutPageMissionDescriptionAr);
        settings.AboutPageVisionTitle = Normalize(request.AboutPageVisionTitle);
        settings.AboutPageVisionTitleAr = Normalize(request.AboutPageVisionTitleAr);
        settings.AboutPageVisionDescription = Normalize(request.AboutPageVisionDescription);
        settings.AboutPageVisionDescriptionAr = Normalize(request.AboutPageVisionDescriptionAr);
        settings.Feature1Title = Normalize(request.Feature1Title);
        settings.Feature1TitleAr = Normalize(request.Feature1TitleAr);
        settings.Feature1Description = Normalize(request.Feature1Description);
        settings.Feature1DescriptionAr = Normalize(request.Feature1DescriptionAr);
        settings.Feature2Title = Normalize(request.Feature2Title);
        settings.Feature2TitleAr = Normalize(request.Feature2TitleAr);
        settings.Feature2Description = Normalize(request.Feature2Description);
        settings.Feature2DescriptionAr = Normalize(request.Feature2DescriptionAr);
        settings.Feature3Title = Normalize(request.Feature3Title);
        settings.Feature3TitleAr = Normalize(request.Feature3TitleAr);
        settings.Feature3Description = Normalize(request.Feature3Description);
        settings.Feature3DescriptionAr = Normalize(request.Feature3DescriptionAr);
        settings.ContactPageTitle = Normalize(request.ContactPageTitle);
        settings.ContactPageTitleAr = Normalize(request.ContactPageTitleAr);
        settings.ContactPageSubtitle = Normalize(request.ContactPageSubtitle);
        settings.ContactPageSubtitleAr = Normalize(request.ContactPageSubtitleAr);
        settings.ContactPageDescription = Normalize(request.ContactPageDescription);
        settings.ContactPageDescriptionAr = Normalize(request.ContactPageDescriptionAr);
        settings.ContactAddress = Normalize(request.ContactAddress);
        settings.ContactAddressAr = Normalize(request.ContactAddressAr);
        settings.ContactWorkingHours = Normalize(request.ContactWorkingHours);
        settings.ContactWorkingHoursAr = Normalize(request.ContactWorkingHoursAr);
        settings.ContactEmail = Normalize(request.ContactEmail);
        settings.ContactPhone = Normalize(request.ContactPhone);
        settings.UpdatedAtUtc = DateTime.UtcNow;

        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return MapAdmin(settings);
    }

    private async Task<LandingPageSettings> GetOrCreateSettingsAsync(CancellationToken cancellationToken)
    {
        var settings = await _applicationDbContext.LandingPageSettings.SingleOrDefaultAsync(cancellationToken);
        if (settings != null)
        {
            return settings;
        }

        settings = new LandingPageSettings
        {
            UpdatedAtUtc = DateTime.UtcNow
        };

        _applicationDbContext.LandingPageSettings.Add(settings);
        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return settings;
    }

    private static LandingPageAdminDto MapAdmin(LandingPageSettings settings) => new()
    {
        SystemName = settings.SystemName,
        SystemNameAr = settings.SystemNameAr,
        Tagline = settings.Tagline,
        TaglineAr = settings.TaglineAr,
        HeroTitle = settings.HeroTitle,
        HeroTitleAr = settings.HeroTitleAr,
        HeroSubtitle = settings.HeroSubtitle,
        HeroSubtitleAr = settings.HeroSubtitleAr,
        PrimaryButtonText = settings.PrimaryButtonText,
        PrimaryButtonTextAr = settings.PrimaryButtonTextAr,
        PrimaryButtonUrl = settings.PrimaryButtonUrl,
        SecondaryButtonText = settings.SecondaryButtonText,
        SecondaryButtonTextAr = settings.SecondaryButtonTextAr,
        SecondaryButtonUrl = settings.SecondaryButtonUrl,
        AboutTitle = settings.AboutTitle,
        AboutTitleAr = settings.AboutTitleAr,
        AboutDescription = settings.AboutDescription,
        AboutDescriptionAr = settings.AboutDescriptionAr,
        AboutPageTitle = settings.AboutPageTitle,
        AboutPageTitleAr = settings.AboutPageTitleAr,
        AboutPageSubtitle = settings.AboutPageSubtitle,
        AboutPageSubtitleAr = settings.AboutPageSubtitleAr,
        AboutPageDescription = settings.AboutPageDescription,
        AboutPageDescriptionAr = settings.AboutPageDescriptionAr,
        AboutPageMissionTitle = settings.AboutPageMissionTitle,
        AboutPageMissionTitleAr = settings.AboutPageMissionTitleAr,
        AboutPageMissionDescription = settings.AboutPageMissionDescription,
        AboutPageMissionDescriptionAr = settings.AboutPageMissionDescriptionAr,
        AboutPageVisionTitle = settings.AboutPageVisionTitle,
        AboutPageVisionTitleAr = settings.AboutPageVisionTitleAr,
        AboutPageVisionDescription = settings.AboutPageVisionDescription,
        AboutPageVisionDescriptionAr = settings.AboutPageVisionDescriptionAr,
        Feature1Title = settings.Feature1Title,
        Feature1TitleAr = settings.Feature1TitleAr,
        Feature1Description = settings.Feature1Description,
        Feature1DescriptionAr = settings.Feature1DescriptionAr,
        Feature2Title = settings.Feature2Title,
        Feature2TitleAr = settings.Feature2TitleAr,
        Feature2Description = settings.Feature2Description,
        Feature2DescriptionAr = settings.Feature2DescriptionAr,
        Feature3Title = settings.Feature3Title,
        Feature3TitleAr = settings.Feature3TitleAr,
        Feature3Description = settings.Feature3Description,
        Feature3DescriptionAr = settings.Feature3DescriptionAr,
        ContactPageTitle = settings.ContactPageTitle,
        ContactPageTitleAr = settings.ContactPageTitleAr,
        ContactPageSubtitle = settings.ContactPageSubtitle,
        ContactPageSubtitleAr = settings.ContactPageSubtitleAr,
        ContactPageDescription = settings.ContactPageDescription,
        ContactPageDescriptionAr = settings.ContactPageDescriptionAr,
        ContactAddress = settings.ContactAddress,
        ContactAddressAr = settings.ContactAddressAr,
        ContactWorkingHours = settings.ContactWorkingHours,
        ContactWorkingHoursAr = settings.ContactWorkingHoursAr,
        ContactEmail = settings.ContactEmail,
        ContactPhone = settings.ContactPhone,
        UpdatedAtUtc = settings.UpdatedAtUtc
    };

    private static string GetLocalized(string preferred, string fallback)
    {
        return string.IsNullOrWhiteSpace(preferred) ? fallback : preferred;
    }

    private static string Normalize(string? value) => (value ?? string.Empty).Trim();
}
