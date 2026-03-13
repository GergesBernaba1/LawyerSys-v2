using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Controllers;

[Authorize(Policy = "CustomerAccess")]
[ApiController]
[Route("api/cases")]
public class CaseConversationController : ControllerBase
{
    private static readonly string[] AllowedUploadExtensions = [".pdf", ".doc", ".docx", ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"];

    private readonly LegacyDbContext _context;
    private readonly IUserContext _userContext;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IWebHostEnvironment _env;

    public CaseConversationController(
        LegacyDbContext context,
        IUserContext userContext,
        IInAppNotificationService inAppNotificationService,
        IWebHostEnvironment env)
    {
        _context = context;
        _userContext = userContext;
        _inAppNotificationService = inAppNotificationService;
        _env = env;
    }

    [HttpGet("{caseCode}/conversation")]
    public async Task<ActionResult<IEnumerable<CaseConversationMessageDto>>> GetConversation(int caseCode)
    {
        if (!await CanAccessCase(caseCode))
        {
            return Forbid();
        }

        var roles = await _userContext.GetUserRolesAsync();
        var isCustomerOnly = roles.Contains("Customer") && !roles.Contains("SuperAdmin") && !roles.Contains("Admin") && !roles.Contains("Employee");
        var currentUserId = _userContext.GetUserId();

        var query = _context.CaseConversationMessages
            .Where(item => item.CaseCode == caseCode);

        if (isCustomerOnly)
        {
            query = query.Where(item => item.VisibleToCustomer);
        }

        var items = await query
            .OrderBy(item => item.CreatedAtUtc)
            .ToListAsync();

        var attachmentIds = items
            .Where(item => item.AttachmentFileId.HasValue)
            .Select(item => item.AttachmentFileId!.Value)
            .Distinct()
            .ToList();

        var attachments = attachmentIds.Count == 0
            ? new Dictionary<int, FileEntity>()
            : await _context.Files
                .AsNoTracking()
                .Where(item => attachmentIds.Contains(item.Id))
                .ToDictionaryAsync(item => item.Id);

        var now = DateTime.UtcNow;
        var changed = false;
        foreach (var item in items)
        {
            if (isCustomerOnly)
            {
                if (!string.Equals(item.SenderRole, "Customer", StringComparison.OrdinalIgnoreCase) && item.ReadByCustomerAtUtc == null)
                {
                    item.ReadByCustomerAtUtc = now;
                    changed = true;
                }
            }
            else if (string.Equals(item.SenderRole, "Customer", StringComparison.OrdinalIgnoreCase) && item.ReadByOfficeAtUtc == null)
            {
                item.ReadByOfficeAtUtc = now;
                changed = true;
            }
        }

        if (changed)
        {
            await _context.SaveChangesAsync(HttpContext.RequestAborted);
        }

        return Ok(items.Select(item =>
        {
            attachments.TryGetValue(item.AttachmentFileId ?? 0, out var attachment);
            return new CaseConversationMessageDto
            {
                Id = item.Id,
                CaseCode = item.CaseCode,
                SenderName = item.SenderName,
                SenderRole = item.SenderRole,
                Message = item.Message,
                VisibleToCustomer = item.VisibleToCustomer,
                AttachmentFileId = item.AttachmentFileId,
                AttachmentFileCode = attachment?.Code ?? string.Empty,
                AttachmentFilePath = attachment?.Path ?? string.Empty,
                CreatedAtUtc = item.CreatedAtUtc,
                ReadByCustomerAtUtc = item.ReadByCustomerAtUtc,
                ReadByOfficeAtUtc = item.ReadByOfficeAtUtc,
                IsMine = item.SenderUserId == (currentUserId ?? string.Empty),
                IsReadByOtherParty = isCustomerOnly
                    ? item.ReadByOfficeAtUtc.HasValue
                    : item.ReadByCustomerAtUtc.HasValue
            };
        }).ToList());
    }

    [HttpPost("{caseCode}/conversation")]
    public Task<ActionResult<CaseConversationMessageDto>> CreateMessage(int caseCode, [FromBody] CreateCaseConversationMessageRequest request)
    {
        return CreateConversationMessageAsync(caseCode, request.Message, request.VisibleToCustomer, null);
    }

    [HttpPost("{caseCode}/conversation/attachment")]
    public Task<ActionResult<CaseConversationMessageDto>> CreateMessageWithAttachment(
        int caseCode,
        [FromForm] string message,
        [FromForm] bool visibleToCustomer = true,
        IFormFile? attachment = null)
    {
        return CreateConversationMessageAsync(caseCode, message, visibleToCustomer, attachment);
    }

    private async Task<ActionResult<CaseConversationMessageDto>> CreateConversationMessageAsync(int caseCode, string? messageValue, bool visibleToCustomer, IFormFile? attachment)
    {
        if (!await CanAccessCase(caseCode))
        {
            return Forbid();
        }

        var roles = await _userContext.GetUserRolesAsync();
        var isCustomerOnly = roles.Contains("Customer") && !roles.Contains("SuperAdmin") && !roles.Contains("Admin") && !roles.Contains("Employee");
        var senderRole = isCustomerOnly ? "Customer" : roles.FirstOrDefault(role => role is "SuperAdmin" or "Admin" or "Employee") ?? "User";
        var message = messageValue?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(message) && attachment == null)
        {
            return BadRequest(new { message = "Message or attachment is required." });
        }

        int? attachmentFileId = null;
        string attachmentFileCode = string.Empty;
        string attachmentFilePath = string.Empty;
        if (attachment != null)
        {
            FileEntity savedAttachment;
            try
            {
                savedAttachment = await SaveUploadedFileAsync(attachment, attachment.FileName, HttpContext.RequestAborted);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            attachmentFileId = savedAttachment.Id;
            attachmentFileCode = savedAttachment.Code ?? string.Empty;
            attachmentFilePath = savedAttachment.Path ?? string.Empty;

            _context.Cases_Files.Add(new Cases_File
            {
                Case_Id = caseCode,
                File_Id = savedAttachment.Id
            });
        }

        var entity = new CaseConversationMessage
        {
            CaseCode = caseCode,
            SenderUserId = _userContext.GetUserId() ?? string.Empty,
            SenderName = ResolveSenderName(),
            SenderRole = senderRole,
            Message = message,
            VisibleToCustomer = isCustomerOnly || visibleToCustomer,
            AttachmentFileId = attachmentFileId,
            CreatedAtUtc = DateTime.UtcNow,
            FirmId = _userContext.GetTenantId() ?? 1
        };

        _context.CaseConversationMessages.Add(entity);
        await _context.SaveChangesAsync(HttpContext.RequestAborted);

        await _inAppNotificationService.NotifyCaseConversationMessageAsync(
            caseCode,
            string.IsNullOrWhiteSpace(message) ? attachmentFileCode : message,
            fromCustomer: isCustomerOnly,
            visibleToCustomer: entity.VisibleToCustomer,
            HttpContext.RequestAborted);

        return Ok(new CaseConversationMessageDto
        {
            Id = entity.Id,
            CaseCode = entity.CaseCode,
            SenderName = entity.SenderName,
            SenderRole = entity.SenderRole,
            Message = entity.Message,
            VisibleToCustomer = entity.VisibleToCustomer,
            AttachmentFileId = entity.AttachmentFileId,
            AttachmentFileCode = attachmentFileCode,
            AttachmentFilePath = attachmentFilePath,
            CreatedAtUtc = entity.CreatedAtUtc,
            ReadByCustomerAtUtc = entity.ReadByCustomerAtUtc,
            ReadByOfficeAtUtc = entity.ReadByOfficeAtUtc,
            IsMine = true,
            IsReadByOtherParty = false
        });
    }

    private string ResolveSenderName()
    {
        return User.FindFirst("fullName")?.Value
            ?? _userContext.GetUserName()
            ?? "System";
    }

    private async Task<FileEntity> SaveUploadedFileAsync(IFormFile file, string? title, CancellationToken cancellationToken)
    {
        if (file.Length == 0)
        {
            throw new InvalidOperationException("No file uploaded");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedUploadExtensions.Contains(extension))
        {
            throw new InvalidOperationException("Unsupported file type. Allowed types: .pdf, .doc, .docx, .png, .jpg, .jpeg, .gif, .bmp, .webp");
        }

        var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
        if (!Directory.Exists(uploadsPath))
        {
            Directory.CreateDirectory(uploadsPath);
        }

        var generatedFileName = $"{Guid.NewGuid()}{extension}";
        var savedPath = Path.Combine(uploadsPath, generatedFileName);

        await using (var stream = new FileStream(savedPath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        var fileEntity = new FileEntity
        {
            Path = $"/Uploads/{generatedFileName}",
            Code = string.IsNullOrWhiteSpace(title)
                ? Path.GetFileNameWithoutExtension(file.FileName)
                : title.Trim(),
            type = extension is ".pdf" or ".doc" or ".docx"
        };

        _context.Files.Add(fileEntity);
        await _context.SaveChangesAsync(cancellationToken);
        return fileEntity;
    }

    private async Task<bool> CanAccessCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin"))
            return true;

        var userName = _userContext.GetUserName();

        if (roles.Contains("Employee"))
        {
            var employee = await _context.Employees
                .Include(item => item.Users)
                .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);

            if (employee == null)
                return false;

            return await _context.Cases_Employees
                .AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employee.id);
        }

        if (roles.Contains("Customer"))
        {
            var customer = await _context.Customers
                .Include(item => item.Users)
                .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);

            if (customer == null)
                return false;

            return await _context.Custmors_Cases
                .AnyAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customer.Id);
        }

        return false;
    }
}
