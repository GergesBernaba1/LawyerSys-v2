using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize(Policy = "CustomerAccess")]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly IUserContext _userContext;
    private readonly INotificationsQueryService _notificationsQueryService;

    public NotificationsController(
        IUserContext userContext,
        INotificationsQueryService notificationsQueryService)
    {
        _userContext = userContext;
        _notificationsQueryService = notificationsQueryService;
    }

    [HttpGet]
    public async Task<ActionResult<NotificationListDto>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 12,
        [FromQuery] NotificationReadFilter filter = NotificationReadFilter.All,
        [FromQuery] NotificationCategoryFilter category = NotificationCategoryFilter.All,
        CancellationToken cancellationToken = default)
    {
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return Unauthorized();
        }

        var result = await _notificationsQueryService.GetNotificationsAsync(currentUserId, page, pageSize, filter, category, cancellationToken);
        return Ok(result);
    }

    [HttpPost("{id:long}/read")]
    public async Task<IActionResult> MarkAsRead(long id, CancellationToken cancellationToken)
    {
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return Unauthorized();
        }

        var result = await _notificationsQueryService.MarkAsReadAsync(currentUserId, id, cancellationToken);
        if (result.NotFound)
        {
            return NotFound(new { message = "Notification not found." });
        }

        return Ok(new { success = true });
    }
}
