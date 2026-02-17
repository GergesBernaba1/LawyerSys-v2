using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "AdminOnly")]
[ApiController]
[Route("api/[controller]")]
public class AuditLogsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public AuditLogsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<AuditLogDto>>> GetAuditLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        [FromQuery] string? search = null,
        [FromQuery] string? entityName = null,
        [FromQuery] string? action = null)
    {
        var p = Math.Max(1, page);
        var ps = Math.Clamp(pageSize, 1, 200);

        IQueryable<LawyerSys.Data.ScaffoldedModels.AuditLog> query = _context.Set<LawyerSys.Data.ScaffoldedModels.AuditLog>();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(a =>
                a.EntityName.Contains(s) ||
                a.Action.Contains(s) ||
                (a.EntityId != null && a.EntityId.Contains(s)) ||
                (a.UserName != null && a.UserName.Contains(s)) ||
                (a.RequestPath != null && a.RequestPath.Contains(s)));
        }

        if (!string.IsNullOrWhiteSpace(entityName))
        {
            var en = entityName.Trim();
            query = query.Where(a => a.EntityName == en);
        }

        if (!string.IsNullOrWhiteSpace(action))
        {
            var act = action.Trim();
            query = query.Where(a => a.Action == act);
        }

        var totalCount = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.Timestamp)
            .Skip((p - 1) * ps)
            .Take(ps)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                EntityName = a.EntityName,
                Action = a.Action,
                EntityId = a.EntityId,
                OldValues = a.OldValues,
                NewValues = a.NewValues,
                UserId = a.UserId,
                UserName = a.UserName,
                Timestamp = a.Timestamp,
                RequestPath = a.RequestPath
            })
            .ToListAsync();

        return Ok(new PagedResult<AuditLogDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = p,
            PageSize = ps
        });
    }
}
