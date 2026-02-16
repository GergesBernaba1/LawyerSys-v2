using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class JudicialDocumentsController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public JudicialDocumentsController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<JudicialDocumentDto>>> GetDocuments()
    {
        var docs = await _context.Judicial_Documents
            .Include(d => d.Customers)
                .ThenInclude(c => c.Users)
            .ToListAsync();
        return Ok(docs.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<JudicialDocumentDto>> GetDocument(int id)
    {
        var doc = await _context.Judicial_Documents
            .Include(d => d.Customers)
                .ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (doc == null)
            return NotFound(new { message = "Document not found" });

        return Ok(MapToDto(doc));
    }

    [HttpGet("bycustomer/{customerId}")]
    public async Task<ActionResult<IEnumerable<JudicialDocumentDto>>> GetByCustomer(int customerId)
    {
        var docs = await _context.Judicial_Documents
            .Include(d => d.Customers)
                .ThenInclude(c => c.Users)
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
            return BadRequest(new { message = "Customer not found" });

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

        return CreatedAtAction(nameof(GetDocument), new { id = doc.Id }, MapToDto(doc));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateDocument(int id, [FromBody] UpdateJudicialDocumentDto dto)
    {
        var doc = await _context.Judicial_Documents
            .Include(d => d.Customers)
                .ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (doc == null)
            return NotFound(new { message = "Document not found" });

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
            return NotFound(new { message = "Document not found" });

        _context.Judicial_Documents.Remove(doc);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Document deleted" });
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
}
