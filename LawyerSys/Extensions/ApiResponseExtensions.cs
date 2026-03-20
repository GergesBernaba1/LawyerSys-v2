using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;

namespace LawyerSys.Extensions;

public static class LocalizationHelper
{
    /// <summary>Returns the Arabic value when the current UI culture is Arabic and the Arabic value is non-empty; otherwise returns the English value.</summary>
    public static string Localize(string? nameEn, string? nameAr)
        => CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && !string.IsNullOrWhiteSpace(nameAr)
            ? nameAr!
            : nameEn ?? string.Empty;
}

public static class ApiResponseExtensions
{
    public static ActionResult ApiResponseError(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string resourceKey, params object[] args)
    {
        var message = localizer[resourceKey, args].Value;
        return controller.BadRequest(new { message });
    }

    public static ActionResult<TDto> ApiResponseError<TDto>(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string resourceKey, params object[] args)
    {
        var message = localizer[resourceKey, args].Value;
        return controller.BadRequest(new { message });
    }

    public static ActionResult<TDto> EntityNotFound<TDto>(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string entityName)
    {
        var message = localizer["EntityNotFound", entityName].Value;
        return controller.NotFound(new { message });
    }

    public static ActionResult EntityNotFound(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string entityName)
    {
        var message = localizer["EntityNotFound", entityName].Value;
        return controller.NotFound(new { message });
    }
}
