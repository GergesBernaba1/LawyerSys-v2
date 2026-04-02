using LawyerSys.DTOs;

namespace LawyerSys.Services.Calendar;

public interface ICalendarService
{
    Task<IReadOnlyList<CalendarEventDto>> GetEventsAsync(DateOnly? fromDate, DateOnly? toDate, CancellationToken cancellationToken = default);
}
