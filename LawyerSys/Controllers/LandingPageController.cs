using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LandingPageController : ControllerBase
{
    private readonly ApplicationDbContext _applicationDbContext;

    public LandingPageController(ApplicationDbContext applicationDbContext)
    {
        _applicationDbContext = applicationDbContext;
    }

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<LandingPagePublicDto>> GetLandingPage()
    {
        var settings = await GetOrCreateSettingsAsync();
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";

        return Ok(new LandingPagePublicDto
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
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin")]
    public async Task<ActionResult<LandingPageAdminDto>> GetLandingPageAdmin()
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var settings = await GetOrCreateSettingsAsync();
        return Ok(MapAdmin(settings));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut]
    public async Task<ActionResult<LandingPageAdminDto>> UpdateLandingPage([FromBody] UpdateLandingPageRequest request)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var settings = await GetOrCreateSettingsAsync();
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
        settings.ContactEmail = Normalize(request.ContactEmail);
        settings.ContactPhone = Normalize(request.ContactPhone);
        settings.UpdatedAtUtc = DateTime.UtcNow;

        await _applicationDbContext.SaveChangesAsync();
        return Ok(MapAdmin(settings));
    }

    private async Task<LandingPageSettings> GetOrCreateSettingsAsync()
    {
        var settings = await _applicationDbContext.LandingPageSettings.SingleOrDefaultAsync();
        if (settings != null)
        {
            return settings;
        }

        settings = new LandingPageSettings
        {
            UpdatedAtUtc = DateTime.UtcNow
        };

        _applicationDbContext.LandingPageSettings.Add(settings);
        await _applicationDbContext.SaveChangesAsync();
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
    public string ContactEmail { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;
}
