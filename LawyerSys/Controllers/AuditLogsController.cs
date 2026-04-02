using LawyerSys.DTOs;
using LawyerSys.Services.Audit;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize(Policy = "AdminOnly")]
[ApiController]
[Route("api/[controller]")]
public class AuditLogsController : ControllerBase
{
    private readonly IAuditLogsService _auditLogsService;

    public AuditLogsController(IAuditLogsService auditLogsService)
    {
        _auditLogsService = auditLogsService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<AuditLogDto>>> GetAuditLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        [FromQuery] string? search = null,
        [FromQuery] string? entityName = null,
        [FromQuery] string? action = null,
        CancellationToken cancellationToken = default)
    {
        var result = await _auditLogsService.GetAuditLogsAsync(page, pageSize, search, entityName, action, cancellationToken);
        return Ok(result);
    }
}
