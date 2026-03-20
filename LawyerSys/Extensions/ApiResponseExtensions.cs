using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;

namespace LawyerSys.Extensions;

public static class ApiResponseExtensions
{
    public static IActionResult ApiResponseError(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string resourceKey, params object[] args)
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

    public static IActionResult EntityNotFound(this ControllerBase controller, IStringLocalizer<SharedResource> localizer, string entityName)
    {
        var message = localizer["EntityNotFound", entityName].Value;
        return controller.NotFound(new { message });
    }
}
