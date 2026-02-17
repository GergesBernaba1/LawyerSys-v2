using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Services.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class DocumentGenerationController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public DocumentGenerationController(LegacyDbContext context)
    {
        _context = context;
    }

    [HttpGet("templates")]
    public ActionResult<IEnumerable<DocumentTemplateDto>> GetTemplates()
    {
        var templates = LegalTemplateGenerator.ListTemplates()
            .Select(t => new DocumentTemplateDto { Key = t.Key, Name = t.Name, Description = t.Description })
            .ToList();

        return Ok(templates);
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateDocumentRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.TemplateType) || !LegalTemplateGenerator.Exists(request.TemplateType))
        {
            return BadRequest(new { message = "Invalid template type" });
        }

        var vars = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Today"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            ["LawyerName"] = User.Identity?.Name ?? "Lawyer",
            ["LawFirmName"] = "LawyerSys Office",
            ["Scope"] = "Provide legal representation and consultation services.",
            ["FeeTerms"] = "As agreed between parties.",
            ["Subject"] = "Case filing statement",
            ["Statement"] = "Detailed legal statement will be inserted here.",
            ["CourtName"] = "N/A",
            ["CaseCode"] = request.CaseCode?.ToString() ?? "N/A",
            ["CaseType"] = "N/A",
            ["CustomerName"] = "N/A"
        };

        if (request.CaseCode.HasValue)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == request.CaseCode.Value);
            if (caseEntity != null)
            {
                vars["CaseCode"] = caseEntity.Code.ToString();
                vars["CaseType"] = caseEntity.Invition_Type;

                var courtName = await _context.Cases_Courts
                    .Where(cc => cc.Case_Code == caseEntity.Code)
                    .Select(cc => cc.Court.Name)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrWhiteSpace(courtName))
                {
                    vars["CourtName"] = courtName;
                }
            }
        }

        var customerId = request.CustomerId;
        if (!customerId.HasValue && request.CaseCode.HasValue)
        {
            customerId = await _context.Custmors_Cases
                .Where(cc => cc.Case_Id == request.CaseCode.Value)
                .Select(cc => (int?)cc.Custmors_Id)
                .FirstOrDefaultAsync();
        }

        if (customerId.HasValue)
        {
            var customerName = await _context.Customers
                .Where(c => c.Id == customerId.Value)
                .Select(c => c.Users.Full_Name)
                .FirstOrDefaultAsync();

            if (!string.IsNullOrWhiteSpace(customerName))
            {
                vars["CustomerName"] = customerName;
            }
        }

        if (request.Variables != null)
        {
            foreach (var kv in request.Variables)
            {
                vars[kv.Key] = kv.Value;
            }
        }

        var content = LegalTemplateGenerator.Render(request.TemplateType, vars);
        var bytes = LegalTemplateGenerator.BuildOutput(content, request.Format);
        var ext = LegalTemplateGenerator.GetFileExtension(request.Format);
        var contentType = LegalTemplateGenerator.GetContentType(request.Format);

        return File(bytes, contentType, $"{request.TemplateType}-{DateTime.UtcNow:yyyyMMddHHmmss}.{ext}");
    }
}
