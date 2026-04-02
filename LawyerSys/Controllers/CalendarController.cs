using LawyerSys.DTOs;
using LawyerSys.Services.Calendar;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CalendarController : ControllerBase
{
    private readonly ICalendarService _calendarService;

    public CalendarController(ICalendarService calendarService)
    {
        _calendarService = calendarService;
    }

    [HttpGet("events")]
    public async Task<ActionResult<IEnumerable<CalendarEventDto>>> GetEvents([FromQuery] DateOnly? fromDate = null, [FromQuery] DateOnly? toDate = null, CancellationToken cancellationToken = default)
    {
        var events = await _calendarService.GetEventsAsync(fromDate, toDate, cancellationToken);
        return Ok(events);
    }
}
