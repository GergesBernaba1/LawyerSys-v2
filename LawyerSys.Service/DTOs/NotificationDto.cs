namespace LawyerSys.DTOs;

public enum NotificationReadFilter
{
    All = 0,
    Unread = 1,
    Read = 2
}

public enum NotificationCategoryFilter
{
    All = 0,
    Case = 1,
    Billing = 2,
    Document = 3,
    Conversation = 4,
    System = 5
}

public class NotificationItemDto
{
    public long Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string EntityName { get; set; } = string.Empty;
    public string? Route { get; set; }
    public string? UserName { get; set; }
    public DateTime Timestamp { get; set; }
    public bool IsRead { get; set; }
}

public class NotificationListDto
{
    public int UnreadCount { get; set; }
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public bool HasMore { get; set; }
    public List<NotificationItemDto> Items { get; set; } = new();
}
