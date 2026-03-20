using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class JudicialDocumentsController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IEmployeeAccessService _employeeAccessService;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public JudicialDocumentsController(
        LegacyDbContext context,
        IEmployeeAccessService employeeAccessService,
        IInAppNotificationService inAppNotificationService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _employeeAccessService = employeeAccessService;
        _inAppNotificationService = inAppNotificationService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<JudicialDocumentDto>>> GetDocuments([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<Judicial_Document> query = _context.Judicial_Documents
            .Include(d => d.Customers).ThenInclude(c => c.Users);

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var assignedCustomerIds = await _employeeAccessService.GetAssignedCustomerIdsAsync();
            query = assignedCustomerIds.Length == 0
                ? query.Where(_ => false)
                : query.Where(d => assignedCustomerIds.Contains(d.Customers_Id));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(d => d.Doc_Type.Contains(s) || d.Doc_Num.ToString().Contains(s) || d.Doc_Details.Contains(s)
                || (d.Customers != null && d.Customers.Users != null && d.Customers.Users.Full_Name.Contains(s)));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(d => d.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<JudicialDocumentDto> { Items = items.Select(MapToDto), TotalCount = total, Page = p, PageSize = ps });
        }

        var list = await query.OrderBy(d => d.Id).ToListAsync();
        return Ok(list.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<JudicialDocumentDto>> GetDocument(int id)
    {
        var doc = await _context.Judicial_Documents
            .Include(d => d.Customers).ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (doc == null)
            return this.EntityNotFound<JudicialDocumentDto>(_localizer, "Document");
        if (!await CanAccessDocumentAsync(doc))
            return Forbid();

        return Ok(MapToDto(doc));
    }

    [HttpGet("bycustomer/{customerId}")]
    public async Task<ActionResult<IEnumerable<JudicialDocumentDto>>> GetByCustomer(int customerId)
    {
        if (!await _employeeAccessService.CanAccessCustomerAsync(customerId) && await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            return Forbid();

        var docs = await _context.Judicial_Documents
            .Include(d => d.Customers).ThenInclude(c => c.Users)
            .Where(d => d.Customers_Id == customerId)
            .ToListAsync();

        return Ok(docs.Select(MapToDto));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<JudicialDocumentDto>> CreateDocument([FromBody] CreateJudicialDocumentDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var customer = await _context.Customers.FindAsync(dto.CustomerId);
        if (customer == null)
            return BadRequest(new { message = _localizer["CustomerNotFound"].Value });
        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync() && !await _employeeAccessService.CanAccessCustomerAsync(dto.CustomerId))
            return Forbid();

        var doc = new Judicial_Document
        {
            Doc_Type = dto.DocType,
            Doc_Num = dto.DocNum,
            Doc_Details = dto.DocDetails,
            Notes = dto.Notes ?? string.Empty,
            Num_Of_Agent = dto.NumOfAgent,
            Customers_Id = dto.CustomerId
        };

        _context.Judicial_Documents.Add(doc);
        await _context.SaveChangesAsync();

        await _context.Entry(doc).Reference(d => d.Customers).LoadAsync();
        await _context.Entry(doc.Customers).Reference(c => c.Users).LoadAsync();

        var caseCodes = await _context.Custmors_Cases
            .Where(item => item.Custmors_Id == dto.CustomerId)
            .Select(item => item.Case_Id)
            .Distinct()
            .ToListAsync();

        foreach (var caseCode in caseCodes)
            await _inAppNotificationService.NotifyCaseDocumentAddedAsync(caseCode, doc.Id, doc.Doc_Type, HttpContext.RequestAborted);

        return CreatedAtAction(nameof(GetDocument), new { id = doc.Id }, MapToDto(doc));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateDocument(int id, [FromBody] UpdateJudicialDocumentDto dto)
    {
        var doc = await _context.Judicial_Documents
            .Include(d => d.Customers).ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (doc == null)
            return this.EntityNotFound(_localizer, "Document");
        if (!await CanAccessDocumentAsync(doc))
            return Forbid();

        if (dto.DocType != null) doc.Doc_Type = dto.DocType;
        if (dto.DocNum.HasValue) doc.Doc_Num = dto.DocNum.Value;
        if (dto.DocDetails != null) doc.Doc_Details = dto.DocDetails;
        if (dto.Notes != null) doc.Notes = dto.Notes;
        if (dto.NumOfAgent.HasValue) doc.Num_Of_Agent = dto.NumOfAgent.Value;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(doc));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteDocument(int id)
    {
        var doc = await _context.Judicial_Documents.FindAsync(id);
        if (doc == null)
            return this.EntityNotFound(_localizer, "Document");
        if (!await CanAccessDocumentAsync(doc))
            return Forbid();

        _context.Judicial_Documents.Remove(doc);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["DocumentDeleted"].Value });
    }

    private static JudicialDocumentDto MapToDto(Judicial_Document d) => new()
    {
        Id = d.Id,
        DocType = d.Doc_Type,
        DocNum = d.Doc_Num,
        DocDetails = d.Doc_Details,
        Notes = d.Notes,
        NumOfAgent = d.Num_Of_Agent,
        CustomerId = d.Customers_Id,
        CustomerName = d.Customers?.Users?.Full_Name
    };

    private async Task<bool> CanAccessDocumentAsync(Judicial_Document document)
    {
        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            return await _employeeAccessService.CanAccessCustomerAsync(document.Customers_Id);
        return true;
    }
}
