using System.Globalization;
using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "CustomerAccess")]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IUserContext _userContext;
    private readonly INotificationRealtimePublisher _realtimePublisher;

    public NotificationsController(
        ApplicationDbContext applicationDbContext,
        IUserContext userContext,
        INotificationRealtimePublisher realtimePublisher)
    {
        _applicationDbContext = applicationDbContext;
        _userContext = userContext;
        _realtimePublisher = realtimePublisher;
    }

    [HttpGet]
    public async Task<ActionResult<NotificationListDto>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 12,
        [FromQuery] NotificationReadFilter filter = NotificationReadFilter.All,
        [FromQuery] NotificationCategoryFilter category = NotificationCategoryFilter.All)
    {
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return Unauthorized();
        }

        var safePage = Math.Max(page, 1);
        var safePageSize = Math.Clamp(pageSize, 1, 50);
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";

        var query = _applicationDbContext.Notifications
            .AsNoTracking()
            .Where(notification => notification.RecipientUserId == currentUserId)
            .AsQueryable();

        if (filter == NotificationReadFilter.Unread)
        {
            query = query.Where(notification => !notification.IsRead);
        }
        else if (filter == NotificationReadFilter.Read)
        {
            query = query.Where(notification => notification.IsRead);
        }

        query = category switch
        {
            NotificationCategoryFilter.Billing => query.Where(notification => notification.Type.Contains("Billing") || notification.Type.Contains("Payment")),
            NotificationCategoryFilter.Document => query.Where(notification => notification.Type.Contains("Document") || notification.Type.Contains("File")),
            NotificationCategoryFilter.Conversation => query.Where(notification => notification.Type.Contains("Conversation") || notification.Type.Contains("Message")),
            NotificationCategoryFilter.Case => query.Where(notification => notification.Type.Contains("Case") || notification.Type.Contains("Siting")),
            NotificationCategoryFilter.System => query.Where(notification =>
                !notification.Type.Contains("Billing") &&
                !notification.Type.Contains("Payment") &&
                !notification.Type.Contains("Document") &&
                !notification.Type.Contains("File") &&
                !notification.Type.Contains("Conversation") &&
                !notification.Type.Contains("Message") &&
                !notification.Type.Contains("Case") &&
                !notification.Type.Contains("Siting")),
            _ => query
        };

        var totalCount = await query.CountAsync();
        var itemsRaw = await query
            .OrderByDescending(notification => notification.CreatedAtUtc)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .Select(notification => new
            {
                notification.Id,
                Title = useArabic && !string.IsNullOrWhiteSpace(notification.TitleAr) ? notification.TitleAr : notification.Title,
                Message = useArabic && !string.IsNullOrWhiteSpace(notification.MessageAr) ? notification.MessageAr : notification.Message,
                Action = notification.Type,
                EntityName = notification.RelatedEntityType ?? string.Empty,
                notification.Route,
                Timestamp = notification.CreatedAtUtc,
                notification.IsRead
            })
            .ToListAsync();
        var items = itemsRaw.Select(notification => new NotificationItemDto
        {
            Id = notification.Id,
            Title = notification.Title,
            Message = notification.Message,
            Action = notification.Action,
            Category = MapCategory(notification.Action),
            EntityName = notification.EntityName,
            Route = notification.Route,
            Timestamp = notification.Timestamp,
            IsRead = notification.IsRead
        }).ToList();

        var unreadCount = await _applicationDbContext.Notifications
            .AsNoTracking()
            .CountAsync(notification => notification.RecipientUserId == currentUserId && !notification.IsRead);

        return Ok(new NotificationListDto
        {
            UnreadCount = unreadCount,
            TotalCount = totalCount,
            Page = safePage,
            PageSize = safePageSize,
            HasMore = (safePage * safePageSize) < totalCount,
            Items = items
        });
    }

    [HttpPost("{id:long}/read")]
    public async Task<IActionResult> MarkAsRead(long id)
    {
        var currentUserId = _userContext.GetUserId();
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return Unauthorized();
        }

        var notification = await _applicationDbContext.Notifications
            .SingleOrDefaultAsync(item => item.Id == id && item.RecipientUserId == currentUserId);

        if (notification == null)
        {
            return NotFound(new { message = "Notification not found." });
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAtUtc = DateTime.UtcNow;
            await _applicationDbContext.SaveChangesAsync();
            await _realtimePublisher.PublishChangedAsync(new[] { currentUserId });
        }

        return Ok(new { success = true });
    }

    private static string MapCategory(string type)
    {
        if (type.Contains("Billing", StringComparison.OrdinalIgnoreCase)
            || type.Contains("Payment", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Billing.ToString();
        }

        if (type.Contains("Document", StringComparison.OrdinalIgnoreCase) || type.Contains("File", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Document.ToString();
        }

        if (type.Contains("Conversation", StringComparison.OrdinalIgnoreCase) || type.Contains("Message", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Conversation.ToString();
        }

        if (type.Contains("Case", StringComparison.OrdinalIgnoreCase) || type.Contains("Siting", StringComparison.OrdinalIgnoreCase))
        {
            return NotificationCategoryFilter.Case.ToString();
        }

        return NotificationCategoryFilter.System.ToString();
    }
}
