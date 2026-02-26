using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services.Documents;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Controllers;

[Authorize(Policy = "EmployeeOrAdmin")]
[ApiController]
[Route("api/[controller]")]
public class ESignController : ControllerBase
{
    private static readonly HashSet<string> AllowedStatuses = new(StringComparer.OrdinalIgnoreCase)
    {
        "Pending",
        "Signed",
        "Declined",
        "Cancelled"
    };

    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;

    public ESignController(LegacyDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ESignRequestDto>>> GetRequests([FromQuery] string? status = null, [FromQuery] string? search = null)
    {
        IQueryable<ESignatureRequest> query = _context.ESignatureRequests.OrderByDescending(x => x.RequestedAt);

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalized = status.Trim();
            query = query.Where(x => x.Status == normalized);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(x =>
                x.RequestTitle.Contains(s) ||
                x.SignerName.Contains(s) ||
                x.SignerEmail.Contains(s));
        }

        var requests = await query.ToListAsync();
        var fileIds = requests.Where(x => x.FileId.HasValue).Select(x => x.FileId!.Value).Distinct().ToList();
        var fileMap = await _context.Files
            .Where(f => fileIds.Contains(f.Id))
            .ToDictionaryAsync(f => f.Id, f => f);

        return Ok(requests.Select(x => MapToDto(x, fileMap.TryGetValue(x.FileId ?? -1, out var file) ? file : null)));
    }

    [HttpPost("requests")]
    public async Task<ActionResult<ESignRequestDto>> CreateRequest([FromBody] CreateESignRequestDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        if (!dto.FileId.HasValue && string.IsNullOrWhiteSpace(dto.TemplateType))
        {
            return BadRequest(new { message = "Either fileId or templateType is required" });
        }

        FileEntity? selectedFile = null;
        if (dto.FileId.HasValue)
        {
            selectedFile = await _context.Files.FirstOrDefaultAsync(x => x.Id == dto.FileId.Value);
            if (selectedFile == null) return BadRequest(new { message = "File not found" });
        }

        if (selectedFile == null && !string.IsNullOrWhiteSpace(dto.TemplateType))
        {
            if (!LegalTemplateGenerator.Exists(dto.TemplateType))
            {
                return BadRequest(new { message = "Invalid template type" });
            }

            var vars = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["Today"] = DateTime.UtcNow.ToString("yyyy-MM-dd"),
                ["SignerName"] = dto.SignerName,
                ["Subject"] = dto.RequestTitle ?? "Signature Request"
            };

            if (dto.Variables != null)
            {
                foreach (var kv in dto.Variables)
                {
                    vars[kv.Key] = kv.Value;
                }
            }

            var content = LegalTemplateGenerator.Render(dto.TemplateType, vars);
            var bytes = LegalTemplateGenerator.BuildOutput(content, "txt");

            var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
            if (!Directory.Exists(uploadsPath)) Directory.CreateDirectory(uploadsPath);

            var generatedName = $"esign-{dto.TemplateType}-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid():N}.txt";
            var fullPath = Path.Combine(uploadsPath, generatedName);
            await System.IO.File.WriteAllBytesAsync(fullPath, bytes);

            selectedFile = new FileEntity
            {
                Path = $"/Uploads/{generatedName}",
                Code = string.IsNullOrWhiteSpace(dto.RequestTitle) ? $"eSign-{DateTime.UtcNow:yyyyMMddHHmmss}" : dto.RequestTitle,
                type = true
            };

            _context.Files.Add(selectedFile);
            await _context.SaveChangesAsync();
        }

        var now = DateTime.UtcNow;
        var request = new ESignatureRequest
        {
            FileId = selectedFile?.Id,
            RequestTitle = string.IsNullOrWhiteSpace(dto.RequestTitle) ? "Signature Request" : dto.RequestTitle.Trim(),
            TemplateType = string.IsNullOrWhiteSpace(dto.TemplateType) ? null : dto.TemplateType.Trim(),
            SignerName = dto.SignerName.Trim(),
            SignerEmail = dto.SignerEmail.Trim(),
            SignerPhoneNumber = string.IsNullOrWhiteSpace(dto.SignerPhoneNumber) ? null : dto.SignerPhoneNumber.Trim(),
            Message = string.IsNullOrWhiteSpace(dto.Message) ? null : dto.Message.Trim(),
            CaseCode = dto.CaseCode,
            CustomerId = dto.CustomerId,
            Status = "Pending",
            RequestedBy = User.Identity?.Name ?? "System",
            RequestedAt = now,
            UpdatedAt = now,
        };

        _context.ESignatureRequests.Add(request);
        await _context.SaveChangesAsync();

        return Ok(MapToDto(request, selectedFile));
    }

    [HttpPost("requests/{id}/status")]
    public async Task<ActionResult<ESignRequestDto>> UpdateStatus(int id, [FromBody] UpdateESignStatusDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var request = await _context.ESignatureRequests.FirstOrDefaultAsync(x => x.Id == id);
        if (request == null) return NotFound(new { message = "Request not found" });

        var normalized = dto.Status.Trim();
        if (!AllowedStatuses.Contains(normalized))
        {
            return BadRequest(new { message = "Invalid status" });
        }

        request.Status = normalized;
        request.ExternalReference = string.IsNullOrWhiteSpace(dto.ExternalReference) ? request.ExternalReference : dto.ExternalReference.Trim();
        request.SignedAt = normalized.Equals("Signed", StringComparison.OrdinalIgnoreCase) ? DateTime.UtcNow : request.SignedAt;
        if (!normalized.Equals("Pending", StringComparison.OrdinalIgnoreCase))
        {
            request.PublicToken = null;
            request.TokenExpiresAt = null;
        }
        request.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        FileEntity? file = null;
        if (request.FileId.HasValue)
        {
            file = await _context.Files.FirstOrDefaultAsync(x => x.Id == request.FileId.Value);
        }

        return Ok(MapToDto(request, file));
    }

    [HttpPost("requests/{id}/share-link")]
    public async Task<ActionResult<ESignShareLinkDto>> CreateShareLink(int id, [FromBody] CreateESignShareLinkDto? dto = null)
    {
        var request = await _context.ESignatureRequests.FirstOrDefaultAsync(x => x.Id == id);
        if (request == null) return NotFound(new { message = "Request not found" });

        var expiresAfterHours = dto?.ExpireAfterHours ?? 72;
        var token = GeneratePublicToken();
        var expiresAt = DateTime.UtcNow.AddHours(Math.Clamp(expiresAfterHours, 1, 720));

        request.PublicToken = token;
        request.TokenExpiresAt = expiresAt;
        request.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var publicSignUrl = $"{Request.Scheme}://{Request.Host}/esign/sign/{token}";
        return Ok(new ESignShareLinkDto
        {
            RequestId = request.Id,
            Token = token,
            PublicSignUrl = publicSignUrl,
            ExpiresAt = expiresAt
        });
    }

    [AllowAnonymous]
    [HttpGet("public/{token}")]
    public async Task<ActionResult<PublicESignRequestDto>> GetPublicRequest(string token)
    {
        var request = await _context.ESignatureRequests.FirstOrDefaultAsync(x => x.PublicToken == token);
        if (request == null) return NotFound(new { message = "Signing request not found" });

        if (request.TokenExpiresAt.HasValue && request.TokenExpiresAt.Value < DateTime.UtcNow)
        {
            return BadRequest(new { message = "Signing link expired" });
        }

        return Ok(new PublicESignRequestDto
        {
            Id = request.Id,
            RequestTitle = request.RequestTitle,
            SignerName = request.SignerName,
            SignerEmail = request.SignerEmail,
            Message = request.Message,
            Status = request.Status,
            RequestedAt = request.RequestedAt,
            TokenExpiresAt = request.TokenExpiresAt,
        });
    }

    [AllowAnonymous]
    [HttpPost("public/{token}/sign")]
    public async Task<ActionResult<PublicESignRequestDto>> PublicSign(string token, [FromBody] PublicSignESignRequestDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var request = await _context.ESignatureRequests.FirstOrDefaultAsync(x => x.PublicToken == token);
        if (request == null) return NotFound(new { message = "Signing request not found" });

        if (request.TokenExpiresAt.HasValue && request.TokenExpiresAt.Value < DateTime.UtcNow)
        {
            return BadRequest(new { message = "Signing link expired" });
        }

        if (!request.Status.Equals("Pending", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "Request is not pending" });
        }

        var previousStatus = request.Status;
        var previousTokenFingerprint = GetTokenFingerprint(token);

        request.Status = "Signed";
        request.SignedByName = dto.SignedByName.Trim();
        request.SignedAt = DateTime.UtcNow;
        request.PublicToken = null;
        request.TokenExpiresAt = null;
        request.UpdatedAt = DateTime.UtcNow;

        _context.AuditLogs.Add(new AuditLog
        {
            EntityName = "ESignatureRequest",
            Action = "PublicSign",
            EntityId = request.Id.ToString(),
            OldValues = JsonSerializer.Serialize(new
            {
                status = previousStatus,
                tokenFingerprint = previousTokenFingerprint
            }),
            NewValues = JsonSerializer.Serialize(new
            {
                status = request.Status,
                signedByName = request.SignedByName,
                signedAt = request.SignedAt
            }),
            UserName = "PublicSigner",
            Timestamp = DateTime.UtcNow,
            RequestPath = HttpContext?.Request?.Path.Value
        });

        await _context.SaveChangesAsync();

        return Ok(new PublicESignRequestDto
        {
            Id = request.Id,
            RequestTitle = request.RequestTitle,
            SignerName = request.SignerName,
            SignerEmail = request.SignerEmail,
            Message = request.Message,
            Status = request.Status,
            RequestedAt = request.RequestedAt,
            TokenExpiresAt = request.TokenExpiresAt,
        });
    }

    private static ESignRequestDto MapToDto(ESignatureRequest request, FileEntity? file) => new()
    {
        Id = request.Id,
        FileId = request.FileId,
        FileCode = file?.Code,
        FilePath = file?.Path,
        RequestTitle = request.RequestTitle,
        TemplateType = request.TemplateType,
        SignerName = request.SignerName,
        SignerEmail = request.SignerEmail,
        SignerPhoneNumber = request.SignerPhoneNumber,
        Message = request.Message,
        CaseCode = request.CaseCode,
        CustomerId = request.CustomerId,
        Status = request.Status,
        ExternalReference = request.ExternalReference,
        PublicToken = request.PublicToken,
        TokenExpiresAt = request.TokenExpiresAt,
        PublicSignUrl = string.IsNullOrWhiteSpace(request.PublicToken) ? null : $"/esign/sign/{request.PublicToken}",
        SignedByName = request.SignedByName,
        RequestedBy = request.RequestedBy,
        RequestedAt = request.RequestedAt,
        SignedAt = request.SignedAt,
        UpdatedAt = request.UpdatedAt,
    };

    private static string GeneratePublicToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes)
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }

    private static string GetTokenFingerprint(string token)
    {
        var bytes = Encoding.UTF8.GetBytes(token);
        var hash = SHA256.HashData(bytes);
        return Convert.ToHexString(hash)[..16];
    }
}
