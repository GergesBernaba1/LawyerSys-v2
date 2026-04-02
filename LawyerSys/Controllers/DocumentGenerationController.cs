using LawyerSys.DTOs;
using LawyerSys.Services.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class DocumentGenerationController : ControllerBase
{
    private readonly IDocumentGenerationService _documentGenerationService;

    public DocumentGenerationController(IDocumentGenerationService documentGenerationService)
    {
        _documentGenerationService = documentGenerationService;
    }

    [HttpGet("templates")]
    public ActionResult<IEnumerable<DocumentTemplateDto>> GetTemplates([FromQuery] string? culture = null)
    {
        var templates = _documentGenerationService.GetTemplates(culture, Request.Headers.AcceptLanguage.FirstOrDefault());
        return Ok(templates);
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate([FromBody] GenerateDocumentRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _documentGenerationService.GenerateAsync(
            request,
            User.Identity?.Name,
            Request.Headers.AcceptLanguage.FirstOrDefault(),
            cancellationToken);

        if (!result.IsValidTemplateType)
        {
            return BadRequest(new { message = "Invalid template type" });
        }

        if (result.SavedToCase)
        {
            return Ok(new GeneratedDocumentResponseDto
            {
                FileId = result.FileId,
                FileName = result.FileName,
                SavedToCase = true
            });
        }

        return File(result.FileBytes!, result.ContentType!, result.FileName);
    }

    [HttpPost("template-preview")]
    public async Task<ActionResult<object>> GetTemplatePreview([FromBody] TemplatePreviewRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _documentGenerationService.GetTemplatePreviewAsync(
            request,
            User.Identity?.Name,
            Request.Headers.AcceptLanguage.FirstOrDefault(),
            cancellationToken);

        if (!result.IsValidTemplateType)
        {
            return BadRequest(new { message = "Invalid template type" });
        }

        return Ok(new { content = result.Content });
    }

    [HttpGet("clauses")]
    public ActionResult<object> GetClauseLibrary([FromQuery] string? culture = null)
    {
        var items = _documentGenerationService
            .GetClauseLibrary(culture, Request.Headers.AcceptLanguage.FirstOrDefault())
            .Select(c => new { key = c.Key, text = c.Text })
            .ToList();

        return Ok(items);
    }

    [HttpGet("history")]
    public async Task<ActionResult<IEnumerable<DocumentHistoryDto>>> GetHistory(
        [FromQuery] int? caseCode = null,
        [FromQuery] int? limit = 50,
        CancellationToken cancellationToken = default)
    {
        var history = await _documentGenerationService.GetHistoryAsync(caseCode, limit, cancellationToken);
        return Ok(history);
    }

    [HttpGet("history/{id}")]
    public async Task<ActionResult<DocumentHistoryDto>> GetHistoryById(int id, CancellationToken cancellationToken)
    {
        var doc = await _documentGenerationService.GetHistoryByIdAsync(id, cancellationToken);
        if (doc == null)
        {
            return NotFound(new { message = "Document history not found" });
        }

        return Ok(doc);
    }

    [HttpGet("history/{id}/content")]
    public async Task<ActionResult<string>> GetHistoryContent(int id, CancellationToken cancellationToken)
    {
        var result = await _documentGenerationService.GetHistoryContentAsync(id, cancellationToken);
        if (result == null)
        {
            return NotFound(new { message = "Document history not found" });
        }

        return Ok(new
        {
            content = result.Content,
            branding = result.Branding,
            parties = result.Parties,
            clauseKeys = result.ClauseKeys
        });
    }

    [HttpGet("drafts")]
    public async Task<ActionResult<IEnumerable<DocumentDraftDto>>> GetDrafts(CancellationToken cancellationToken)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var drafts = await _documentGenerationService.GetDraftsAsync(userName, cancellationToken);
        return Ok(drafts);
    }

    [HttpGet("drafts/{id}")]
    public async Task<ActionResult<DocumentDraftDto>> GetDraftById(int id, CancellationToken cancellationToken)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var draft = await _documentGenerationService.GetDraftByIdAsync(id, userName, cancellationToken);
        if (draft == null)
        {
            return NotFound(new { message = "Draft not found" });
        }

        return Ok(draft);
    }

    [HttpPost("drafts")]
    public async Task<ActionResult<DocumentDraftDto>> CreateDraft([FromBody] CreateDraftDto dto, CancellationToken cancellationToken)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var draft = await _documentGenerationService.CreateDraftAsync(dto, userName, cancellationToken);
        return CreatedAtAction(nameof(GetDraftById), new { id = draft.Id }, draft);
    }

    [HttpPut("drafts/{id}")]
    public async Task<IActionResult> UpdateDraft(int id, [FromBody] UpdateDraftDto dto, CancellationToken cancellationToken)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var updated = await _documentGenerationService.UpdateDraftAsync(id, dto, userName, cancellationToken);
        if (!updated)
        {
            return NotFound(new { message = "Draft not found" });
        }

        return NoContent();
    }

    [HttpDelete("drafts/{id}")]
    public async Task<IActionResult> DeleteDraft(int id, CancellationToken cancellationToken)
    {
        var userName = User.Identity?.Name ?? string.Empty;
        var deleted = await _documentGenerationService.DeleteDraftAsync(id, userName, cancellationToken);
        if (!deleted)
        {
            return NotFound(new { message = "Draft not found" });
        }

        return NoContent();
    }

    [HttpGet("history/{id}/versions")]
    public async Task<ActionResult<DocumentVersionChainDto>> GetVersionChain(int id, CancellationToken cancellationToken)
    {
        var chain = await _documentGenerationService.GetVersionChainAsync(id, cancellationToken);
        if (chain == null)
        {
            return NotFound(new { message = "Document not found" });
        }

        return Ok(chain);
    }

    [HttpPost("history/{id}/regenerate")]
    public async Task<ActionResult<GeneratedDocumentResponseDto>> RegenerateAsNewVersion(int id, [FromBody] RegenerateDocumentDto? dto = null, CancellationToken cancellationToken = default)
    {
        var result = await _documentGenerationService.RegenerateAsNewVersionAsync(id, dto, User.Identity?.Name, cancellationToken);
        if (result == null)
        {
            return NotFound(new { message = "Original document not found" });
        }

        return Ok(result);
    }

    [HttpPost("history/{id}/restore")]
    public async Task<ActionResult<RestoreVersionResponseDto>> RestoreVersion(int id, CancellationToken cancellationToken)
    {
        var result = await _documentGenerationService.RestoreVersionAsync(id, User.Identity?.Name, cancellationToken);
        if (result == null)
        {
            return NotFound(new { message = "Document version not found" });
        }

        return Ok(result);
    }
}
