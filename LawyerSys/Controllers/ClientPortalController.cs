using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Services.Notifications;
using LawyerSys.Services.Pdf;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using System.Security.Claims;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Controllers;

[Authorize(Policy = "CustomerAccess")]
[ApiController]
[Route("api/[controller]")]
public class ClientPortalController : ControllerBase
{
    private static readonly string[] AllowedUploadExtensions = [".pdf", ".doc", ".docx", ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp"];

    private readonly ApplicationDbContext _applicationDbContext;
    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly IInAppNotificationService _inAppNotificationService;

    public ClientPortalController(
        ApplicationDbContext applicationDbContext,
        LegacyDbContext context,
        IWebHostEnvironment env,
        IInAppNotificationService inAppNotificationService)
    {
        _applicationDbContext = applicationDbContext;
        _context = context;
        _env = env;
        _inAppNotificationService = inAppNotificationService;
    }

    [HttpGet("overview")]
    public async Task<ActionResult<ClientPortalResponseDto>> GetOverview()
    {
        var userName = User.Identity?.Name;
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (string.IsNullOrWhiteSpace(userName))
        {
            return Unauthorized(new { message = "User identity not found" });
        }

        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var customer = await GetCurrentCustomerAsync(userName);

        if (customer is null)
        {
            if (User.IsInRole("Admin") || User.IsInRole("Employee"))
            {
                return Ok(BuildEmptyResponse(userName));
            }

            return NotFound(new { message = "Customer profile not found" });
        }

        var caseCodes = await _context.Custmors_Cases
            .Where(cc => cc.Custmors_Id == customer.Id)
            .Select(cc => cc.Case_Id)
            .Distinct()
            .ToListAsync();

        var latestStatusChanges = await _context.CaseStatusHistories
            .Where(item => caseCodes.Contains(item.Case_Id))
            .GroupBy(item => item.Case_Id)
            .Select(group => new
            {
                CaseCode = group.Key,
                Latest = group
                    .OrderByDescending(entry => entry.ChangedAt)
                    .Select(entry => entry.ChangedAt)
                    .FirstOrDefault()
            })
            .ToDictionaryAsync(item => item.CaseCode, item => item.Latest);

        var cases = await _context.Cases
            .Where(c => caseCodes.Contains(c.Code))
            .OrderByDescending(c => c.Invition_Date)
            .Select(c => new ClientPortalCaseDto
            {
                Code = c.Code,
                Type = c.Invition_Type,
                Date = c.Invition_Date,
                TotalAmount = c.Total_Amount,
                Status = c.Status,
                LatestUpdate = string.Empty
            })
            .ToListAsync();

        foreach (var item in cases)
        {
            if (latestStatusChanges.TryGetValue(item.Code, out var latest))
            {
                item.LatestUpdate = latest.ToString("yyyy-MM-dd HH:mm");
            }
        }

        var hearings = await _context.Cases_Sitings
            .Where(cs => caseCodes.Contains(cs.Case_Code))
            .OrderBy(cs => cs.Siting.Siting_Date)
            .Select(cs => new ClientPortalHearingDto
            {
                CaseCode = cs.Case_Code,
                Date = cs.Siting.Siting_Date,
                Time = cs.Siting.Siting_Time,
                JudgeName = cs.Siting.Judge_Name,
                Notes = cs.Siting.Notes
            })
            .ToListAsync();

        var documents = await _context.Judicial_Documents
            .Where(d => d.Customers_Id == customer.Id)
            .OrderByDescending(d => d.Id)
            .Select(d => new ClientPortalDocumentDto
            {
                Id = d.Id,
                Type = d.Doc_Type,
                Number = d.Doc_Num,
                Details = d.Doc_Details
            })
            .ToListAsync();

        var payments = await _context.Billing_Pays
            .Where(p => p.Custmor_Id == customer.Id)
            .OrderByDescending(p => p.Date_Of_Opreation)
            .Select(p => new ClientPortalPaymentDto
            {
                Id = p.Id,
                Date = p.Date_Of_Opreation,
                Amount = p.Amount,
                Notes = p.Notes
            })
            .ToListAsync();

        var caseFiles = await _context.Cases_Files
            .Include(cf => cf.File)
            .Where(cf => caseCodes.Contains(cf.Case_Id))
            .OrderByDescending(cf => cf.Id)
            .Select(cf => new ClientPortalCaseFileDto
            {
                FileId = cf.File_Id,
                CaseCode = cf.Case_Id,
                FileCode = cf.File != null
                    ? (cf.File.Code ?? string.Empty)
                    : string.Empty,
                FilePath = cf.File != null
                    ? (cf.File.Path ?? string.Empty)
                    : string.Empty
            })
            .ToListAsync();

        var requestedDocumentsRaw = await _context.CustomerRequestedDocuments
            .Where(item => item.CustomerId == customer.Id)
            .OrderByDescending(item => item.RequestedAtUtc)
            .ToListAsync();

        var requestedFileIds = requestedDocumentsRaw
            .Where(item => item.UploadedFileId.HasValue)
            .Select(item => item.UploadedFileId!.Value)
            .Distinct()
            .ToList();

        var requestedFiles = requestedFileIds.Count == 0
            ? new Dictionary<int, FileEntity>()
            : await _context.Files
                .Where(item => requestedFileIds.Contains(item.Id))
                .ToDictionaryAsync(item => item.Id);

        var requestedDocuments = requestedDocumentsRaw
            .Select(item =>
            {
                requestedFiles.TryGetValue(item.UploadedFileId ?? 0, out var file);
                return new CustomerRequestedDocumentDto
                {
                    Id = item.Id,
                    CaseCode = item.CaseCode,
                    CustomerId = item.CustomerId,
                    CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? string.Empty,
                    Title = item.Title,
                    Description = item.Description,
                    DueDate = item.DueDate,
                    Status = item.Status,
                    RequestedByName = item.RequestedByName,
                    CustomerNotes = item.CustomerNotes,
                    ReviewNotes = item.ReviewNotes,
                    UploadedFileId = item.UploadedFileId,
                    UploadedFileCode = file?.Code ?? string.Empty,
                    UploadedFilePath = file?.Path ?? string.Empty,
                    RequestedAtUtc = item.RequestedAtUtc,
                    SubmittedAtUtc = item.SubmittedAtUtc,
                    ReviewedAtUtc = item.ReviewedAtUtc
                };
            })
            .ToList();

        var paymentProofsRaw = await _context.CustomerPaymentProofs
            .Where(item => item.CustomerId == customer.Id)
            .OrderByDescending(item => item.SubmittedAtUtc)
            .ToListAsync();

        var proofFileIds = paymentProofsRaw
            .Where(item => item.ProofFileId.HasValue)
            .Select(item => item.ProofFileId!.Value)
            .Distinct()
            .ToList();

        var proofFiles = proofFileIds.Count == 0
            ? new Dictionary<int, FileEntity>()
            : await _context.Files
                .Where(item => proofFileIds.Contains(item.Id))
                .ToDictionaryAsync(item => item.Id);

        var paymentProofs = paymentProofsRaw
            .Select(item =>
            {
                proofFiles.TryGetValue(item.ProofFileId ?? 0, out var file);
                return new CustomerPaymentProofDto
                {
                    Id = item.Id,
                    CustomerId = item.CustomerId,
                    CaseCode = item.CaseCode,
                    CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? string.Empty,
                    Amount = item.Amount,
                    PaymentDate = item.PaymentDate,
                    Notes = item.Notes,
                    ProofFileId = item.ProofFileId,
                    ProofFileCode = file?.Code ?? string.Empty,
                    ProofFilePath = file?.Path ?? string.Empty,
                    Status = item.Status,
                    BillingPaymentId = item.BillingPaymentId,
                    ReviewNotes = item.ReviewNotes,
                    SubmittedAtUtc = item.SubmittedAtUtc,
                    ReviewedAtUtc = item.ReviewedAtUtc
                };
            })
            .ToList();

        var totalPayments = payments.Sum(p => p.Amount);
        var totalCaseAmount = cases.Sum(c => (double)c.TotalAmount);
        var conversationMessages = caseCodes.Count == 0
            ? new List<LawyerSys.Data.ScaffoldedModels.CaseConversationMessage>()
            : await _context.CaseConversationMessages
                .AsNoTracking()
                .Where(item => caseCodes.Contains(item.CaseCode) && item.VisibleToCustomer)
                .OrderByDescending(item => item.CreatedAtUtc)
                .ToListAsync();

        var messageGroups = conversationMessages
            .GroupBy(item => item.CaseCode)
            .ToDictionary(group => group.Key, group => group.ToList());

        var conversationThreads = cases
            .Select(item =>
            {
                var hasThread = messageGroups.TryGetValue(item.Code, out var threadMessages);
                var latest = hasThread ? threadMessages![0] : null;
                var unreadCount = hasThread
                    ? threadMessages!.Count(message =>
                        !string.Equals(message.SenderRole, "Customer", StringComparison.OrdinalIgnoreCase)
                        && message.ReadByCustomerAtUtc == null)
                    : 0;

                return new ClientPortalConversationThreadDto
                {
                    CaseCode = item.Code,
                    CaseType = item.Type,
                    LastMessage = latest?.Message ?? string.Empty,
                    LastSenderName = latest?.SenderName ?? string.Empty,
                    LastSenderRole = latest?.SenderRole ?? string.Empty,
                    LastMessageAtUtc = latest?.CreatedAtUtc,
                    UnreadCount = unreadCount,
                    WaitingOnCustomer = latest != null && !string.Equals(latest.SenderRole, "Customer", StringComparison.OrdinalIgnoreCase),
                    HasAttachment = latest?.AttachmentFileId.HasValue ?? false
                };
            })
            .OrderByDescending(item => item.UnreadCount)
            .ThenByDescending(item => item.LastMessageAtUtc ?? DateTime.MinValue)
            .ToList();

        var officeContacts = caseCodes.Count == 0
            ? new List<ClientPortalContactDto>()
            : (await _context.Cases_Employees
                .AsNoTracking()
                .Where(item => caseCodes.Contains(item.Case_Code))
                .Select(item => new ClientPortalContactDto
                {
                    EmployeeId = item.Employee_Id,
                    Name = item.Employee.Users.Full_Name,
                    JobTitle = item.Employee.Users.Job,
                    PhoneNumber = item.Employee.Users.Phon_Number.ToString()
                })
                .ToListAsync())
                .GroupBy(item => item.EmployeeId)
                .Select(group => group.First())
                .OrderBy(item => item.Name)
                .ToList();

        var recentUpdates = string.IsNullOrWhiteSpace(currentUserId)
            ? new List<ClientPortalRecentUpdateDto>()
            : await _applicationDbContext.Notifications
                .AsNoTracking()
                .Where(notification => notification.RecipientUserId == currentUserId)
                .OrderByDescending(notification => notification.CreatedAtUtc)
                .Take(8)
                .Select(notification => new ClientPortalRecentUpdateDto
                {
                    Id = notification.Id,
                    Title = useArabic && !string.IsNullOrWhiteSpace(notification.TitleAr) ? notification.TitleAr : notification.Title,
                    Message = useArabic && !string.IsNullOrWhiteSpace(notification.MessageAr) ? notification.MessageAr : notification.Message,
                    Category = MapNotificationCategory(notification.Type),
                    Route = notification.Route ?? string.Empty,
                    Timestamp = notification.CreatedAtUtc
                })
                .ToListAsync();

        var nowUtc = DateTime.UtcNow;
        var upcomingSessions = hearings
            .Select(item => new
            {
                item.CaseCode,
                item.Date,
                item.Time,
                ScheduledAtUtc = item.Date.ToDateTime(TimeOnly.FromDateTime(item.Time))
            })
            .Where(item => item.ScheduledAtUtc >= nowUtc)
            .OrderBy(item => item.ScheduledAtUtc)
            .ToList();

        var nextSession = upcomingSessions.FirstOrDefault();

        return Ok(new ClientPortalResponseDto
        {
            CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? $"Customer #{customer.Id}",
            Cases = cases,
            Hearings = hearings,
            Documents = documents,
            Payments = payments,
            CaseFiles = caseFiles,
            RequestedDocuments = requestedDocuments,
            PaymentProofs = paymentProofs,
            RecentUpdates = recentUpdates,
            ConversationThreads = conversationThreads,
            OfficeContacts = officeContacts,
            Billing = new ClientPortalBillingDto
            {
                TotalPayments = totalPayments,
                CasesTotalAmount = totalCaseAmount,
                OutstandingBalance = totalCaseAmount - totalPayments
            },
            Summary = new ClientPortalSummaryDto
            {
                ActiveCasesCount = cases.Count,
                PendingRequestedDocumentsCount = requestedDocuments.Count(item => !string.Equals(item.Status, "Approved", StringComparison.OrdinalIgnoreCase)),
                UnreadMessagesCount = conversationThreads.Sum(item => item.UnreadCount),
                UpcomingSessionsCount = upcomingSessions.Count,
                PendingPaymentProofsCount = paymentProofs.Count(item => string.Equals(item.Status, "Pending", StringComparison.OrdinalIgnoreCase)),
                NextSessionAtUtc = nextSession?.ScheduledAtUtc,
                NextSessionLabel = nextSession == null ? string.Empty : $"#{nextSession.CaseCode}"
            }
        });
    }

    [HttpPost("cases/{caseCode}/files")]
    public async Task<ActionResult<ClientPortalCaseFileDto>> UploadCaseFile(
        int caseCode,
        IFormFile file,
        [FromForm] string? title)
    {
        var customer = await GetCurrentCustomerOrThrowAsync();
        if (customer is null)
        {
            return NotFound(new { message = "Customer profile not found" });
        }

        if (!await CustomerHasAccessToCaseAsync(customer.Id, caseCode))
        {
            return Forbid();
        }

        FileEntity fileEntity;
        try
        {
            fileEntity = await SaveUploadedFileAsync(file, title, HttpContext.RequestAborted);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        _context.Cases_Files.Add(new LawyerSys.Data.ScaffoldedModels.Cases_File
        {
            Case_Id = caseCode,
            File_Id = fileEntity.Id
        });

        await _context.SaveChangesAsync();

        return Ok(new ClientPortalCaseFileDto
        {
            FileId = fileEntity.Id,
            CaseCode = caseCode,
            FileCode = fileEntity.Code ?? string.Empty,
            FilePath = fileEntity.Path ?? string.Empty
        });
    }

    [HttpPost("cases/{caseCode}/requested-documents/{requestId:long}/submit")]
    public async Task<ActionResult<CustomerRequestedDocumentDto>> SubmitRequestedDocument(
        int caseCode,
        long requestId,
        IFormFile file,
        [FromForm] string? notes)
    {
        var customer = await GetCurrentCustomerOrThrowAsync();
        if (customer is null)
        {
            return NotFound(new { message = "Customer profile not found" });
        }

        var request = await _context.CustomerRequestedDocuments.SingleOrDefaultAsync(item =>
            item.Id == requestId &&
            item.CaseCode == caseCode &&
            item.CustomerId == customer.Id);

        if (request == null)
        {
            return NotFound(new { message = "Requested document not found" });
        }

        if (!await CustomerHasAccessToCaseAsync(customer.Id, caseCode))
        {
            return Forbid();
        }

        FileEntity fileEntity;
        try
        {
            fileEntity = await SaveUploadedFileAsync(file, request.Title, HttpContext.RequestAborted);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        _context.Cases_Files.Add(new LawyerSys.Data.ScaffoldedModels.Cases_File
        {
            Case_Id = caseCode,
            File_Id = fileEntity.Id
        });

        request.UploadedFileId = fileEntity.Id;
        request.CustomerNotes = string.IsNullOrWhiteSpace(notes) ? request.CustomerNotes : notes.Trim();
        request.Status = "Submitted";
        request.SubmittedAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        await _inAppNotificationService.NotifyRequestedDocumentSubmittedAsync(caseCode, request.Id, request.Title, HttpContext.RequestAborted);

        return Ok(new CustomerRequestedDocumentDto
        {
            Id = request.Id,
            CaseCode = request.CaseCode,
            CustomerId = request.CustomerId,
            CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? string.Empty,
            Title = request.Title,
            Description = request.Description,
            DueDate = request.DueDate,
            Status = request.Status,
            RequestedByName = request.RequestedByName,
            CustomerNotes = request.CustomerNotes,
            ReviewNotes = request.ReviewNotes,
            UploadedFileId = request.UploadedFileId,
            UploadedFileCode = fileEntity.Code ?? string.Empty,
            UploadedFilePath = fileEntity.Path ?? string.Empty,
            RequestedAtUtc = request.RequestedAtUtc,
            SubmittedAtUtc = request.SubmittedAtUtc,
            ReviewedAtUtc = request.ReviewedAtUtc
        });
    }

    [HttpPost("cases/{caseCode}/payment-proofs")]
    public async Task<ActionResult<CustomerPaymentProofDto>> SubmitPaymentProof(
        int caseCode,
        [FromForm] double amount,
        [FromForm] DateOnly paymentDate,
        [FromForm] string? notes,
        IFormFile file)
    {
        if (amount <= 0)
        {
            return BadRequest(new { message = "Amount must be greater than zero." });
        }

        var customer = await GetCurrentCustomerOrThrowAsync();
        if (customer is null)
        {
            return NotFound(new { message = "Customer profile not found" });
        }

        if (!await CustomerHasAccessToCaseAsync(customer.Id, caseCode))
        {
            return Forbid();
        }

        FileEntity fileEntity;
        try
        {
            fileEntity = await SaveUploadedFileAsync(file, $"Payment proof {amount:F2}", HttpContext.RequestAborted);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }

        var proof = new LawyerSys.Data.ScaffoldedModels.CustomerPaymentProof
        {
            CustomerId = customer.Id,
            CaseCode = caseCode,
            Amount = amount,
            PaymentDate = paymentDate,
            Notes = notes?.Trim() ?? string.Empty,
            ProofFileId = fileEntity.Id,
            Status = "Pending",
            SubmittedAtUtc = DateTime.UtcNow
        };

        _context.CustomerPaymentProofs.Add(proof);
        _context.Cases_Files.Add(new LawyerSys.Data.ScaffoldedModels.Cases_File
        {
            Case_Id = caseCode,
            File_Id = fileEntity.Id
        });
        await _context.SaveChangesAsync();

        await _inAppNotificationService.NotifyPaymentProofSubmittedAsync(caseCode, proof.Id, amount, HttpContext.RequestAborted);

        return Ok(new CustomerPaymentProofDto
        {
            Id = proof.Id,
            CustomerId = proof.CustomerId,
            CaseCode = proof.CaseCode,
            CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? string.Empty,
            Amount = proof.Amount,
            PaymentDate = proof.PaymentDate,
            Notes = proof.Notes,
            ProofFileId = proof.ProofFileId,
            ProofFileCode = fileEntity.Code ?? string.Empty,
            ProofFilePath = fileEntity.Path ?? string.Empty,
            Status = proof.Status,
            BillingPaymentId = proof.BillingPaymentId,
            ReviewNotes = proof.ReviewNotes,
            SubmittedAtUtc = proof.SubmittedAtUtc,
            ReviewedAtUtc = proof.ReviewedAtUtc
        });
    }

    [HttpGet("payments/{paymentId:int}/receipt")]
    public async Task<IActionResult> DownloadReceipt(int paymentId)
    {
        var customer = await GetCurrentCustomerOrThrowAsync();
        if (customer is null)
        {
            return NotFound(new { message = "Customer profile not found" });
        }

        var payment = await _context.Billing_Pays
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Id == paymentId && item.Custmor_Id == customer.Id);

        if (payment == null)
        {
            return NotFound(new { message = "Payment not found" });
        }
        var officeName = User.FindFirst("tenant_name")?.Value ?? "Qadaya";
        var officePhone = User.FindFirst("tenant_phone")?.Value ?? string.Empty;
        var caseCode = await _context.Custmors_Cases
            .Where(item => item.Custmors_Id == customer.Id)
            .Select(item => (int?)item.Case_Id)
            .FirstOrDefaultAsync();

        var pdfBytes = ReceiptPdfBuilder.BuildCustomerReceipt(
            officeName,
            officePhone,
            customer.Users?.Full_Name ?? customer.Users?.User_Name ?? customer.Id.ToString(),
            payment.Id,
            payment.Date_Of_Opreation,
            payment.Amount,
            payment.Notes,
            caseCode);

        return File(pdfBytes, "application/pdf", $"receipt-{payment.Id}.pdf");
    }

    private static ClientPortalResponseDto BuildEmptyResponse(string customerName) => new()
    {
        CustomerName = customerName,
        Cases = Array.Empty<ClientPortalCaseDto>(),
        Hearings = Array.Empty<ClientPortalHearingDto>(),
        Documents = Array.Empty<ClientPortalDocumentDto>(),
        Payments = Array.Empty<ClientPortalPaymentDto>(),
        CaseFiles = Array.Empty<ClientPortalCaseFileDto>(),
        RequestedDocuments = Array.Empty<CustomerRequestedDocumentDto>(),
        PaymentProofs = Array.Empty<CustomerPaymentProofDto>(),
        RecentUpdates = Array.Empty<ClientPortalRecentUpdateDto>(),
        ConversationThreads = Array.Empty<ClientPortalConversationThreadDto>(),
        OfficeContacts = Array.Empty<ClientPortalContactDto>(),
        Billing = new ClientPortalBillingDto
        {
            TotalPayments = 0,
            CasesTotalAmount = 0,
            OutstandingBalance = 0
        },
        Summary = new ClientPortalSummaryDto()
    };

    private async Task<LawyerSys.Data.ScaffoldedModels.Customer?> GetCurrentCustomerOrThrowAsync()
    {
        var userName = User.Identity?.Name;
        return string.IsNullOrWhiteSpace(userName)
            ? null
            : await GetCurrentCustomerAsync(userName);
    }

    private Task<LawyerSys.Data.ScaffoldedModels.Customer?> GetCurrentCustomerAsync(string userName)
    {
        return _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Users != null && c.Users.User_Name == userName);
    }

    private Task<bool> CustomerHasAccessToCaseAsync(int customerId, int caseCode)
    {
        return _context.Custmors_Cases.AnyAsync(cc => cc.Custmors_Id == customerId && cc.Case_Id == caseCode);
    }

    private async Task<FileEntity> SaveUploadedFileAsync(IFormFile file, string? title, CancellationToken cancellationToken)
    {
        if (file == null || file.Length == 0)
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

    private static string MapNotificationCategory(string type)
    {
        if (type.Contains("Billing", StringComparison.OrdinalIgnoreCase)
            || type.Contains("Payment", StringComparison.OrdinalIgnoreCase))
        {
            return "Billing";
        }

        if (type.Contains("Document", StringComparison.OrdinalIgnoreCase)
            || type.Contains("File", StringComparison.OrdinalIgnoreCase))
        {
            return "Document";
        }

        if (type.Contains("Conversation", StringComparison.OrdinalIgnoreCase)
            || type.Contains("Message", StringComparison.OrdinalIgnoreCase))
        {
            return "Conversation";
        }

        if (type.Contains("Case", StringComparison.OrdinalIgnoreCase)
            || type.Contains("Siting", StringComparison.OrdinalIgnoreCase))
        {
            return "Case";
        }

        return "System";
    }
}
