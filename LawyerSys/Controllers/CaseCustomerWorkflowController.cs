using LawyerSys.Data;
using LawyerSys.DTOs;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;

namespace LawyerSys.Controllers;

[Authorize(Policy = "CustomerAccess")]
[ApiController]
[Route("api/cases")]
public class CaseCustomerWorkflowController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IUserContext _userContext;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CaseCustomerWorkflowController(
        LegacyDbContext context,
        IUserContext userContext,
        IInAppNotificationService inAppNotificationService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _userContext = userContext;
        _inAppNotificationService = inAppNotificationService;
        _localizer = localizer;
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/requested-documents")]
    public async Task<ActionResult<CustomerRequestedDocumentDto>> CreateRequestedDocument(int caseCode, [FromBody] CreateCustomerRequestedDocumentRequest request)
    {
        if (!await CanModifyCase(caseCode))
        {
            return Forbid();
        }

        var customer = await _context.Customers
            .Include(item => item.Users)
            .SingleOrDefaultAsync(item => item.Id == request.CustomerId);

        if (customer == null)
        {
            return BadRequest(new { message = _localizer["CustomerNotFound"].Value });
        }

        var isLinked = await _context.Custmors_Cases.AnyAsync(item => item.Case_Id == caseCode && item.Custmors_Id == request.CustomerId);
        if (!isLinked)
        {
            return BadRequest(new { message = _localizer["CustomerNotLinkedToCase"].Value });
        }

        var entity = new LawyerSys.Data.ScaffoldedModels.CustomerRequestedDocument
        {
            CaseCode = caseCode,
            CustomerId = request.CustomerId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim() ?? string.Empty,
            DueDate = request.DueDate,
            Status = "Pending",
            RequestedByUserId = _userContext.GetUserId() ?? string.Empty,
            RequestedByName = ResolveSenderName(),
            RequestedAtUtc = DateTime.UtcNow
        };

        _context.CustomerRequestedDocuments.Add(entity);
        await _context.SaveChangesAsync();
        await _inAppNotificationService.NotifyRequestedDocumentCreatedAsync(caseCode, entity.Id, entity.Title, HttpContext.RequestAborted);

        return Ok(new CustomerRequestedDocumentDto
        {
            Id = entity.Id,
            CaseCode = entity.CaseCode,
            CustomerId = entity.CustomerId,
            CustomerName = customer.Users?.Full_Name ?? customer.Users?.User_Name ?? string.Empty,
            Title = entity.Title,
            Description = entity.Description,
            DueDate = entity.DueDate,
            Status = entity.Status,
            RequestedByName = entity.RequestedByName,
            RequestedAtUtc = entity.RequestedAtUtc
        });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/requested-documents/{requestId:long}/review")]
    public async Task<ActionResult<CustomerRequestedDocumentDto>> ReviewRequestedDocument(int caseCode, long requestId, [FromBody] ReviewCustomerRequestedDocumentRequest request)
    {
        if (!await CanModifyCase(caseCode))
        {
            return Forbid();
        }

        var entity = await _context.CustomerRequestedDocuments.SingleOrDefaultAsync(item => item.Id == requestId && item.CaseCode == caseCode);
        if (entity == null)
        {
            return NotFound(new { message = _localizer["RequestedDocumentNotFound"].Value });
        }

        entity.Status = request.Status;
        entity.ReviewNotes = request.ReviewNotes?.Trim() ?? string.Empty;
        entity.ReviewedAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        await _inAppNotificationService.NotifyRequestedDocumentReviewedAsync(caseCode, entity.Id, entity.Title, approved: request.Status == "Approved", HttpContext.RequestAborted);

        return Ok(await MapRequestedDocumentAsync(entity));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/payment-proofs/{proofId:long}/review")]
    public async Task<ActionResult<CustomerPaymentProofDto>> ReviewPaymentProof(int caseCode, long proofId, [FromBody] ReviewCustomerPaymentProofRequest request)
    {
        if (!await CanModifyCase(caseCode))
        {
            return Forbid();
        }

        var proof = await _context.CustomerPaymentProofs.SingleOrDefaultAsync(item => item.Id == proofId && item.CaseCode == caseCode);
        if (proof == null)
        {
            return NotFound(new { message = _localizer["PaymentProofNotFound"].Value });
        }

        proof.Status = request.Status;
        proof.ReviewNotes = request.ReviewNotes?.Trim() ?? string.Empty;
        proof.ReviewedByUserId = _userContext.GetUserId() ?? string.Empty;
        proof.ReviewedByName = ResolveSenderName();
        proof.ReviewedAtUtc = DateTime.UtcNow;

        if (request.Status == "Approved" && !proof.BillingPaymentId.HasValue)
        {
            var payment = new LawyerSys.Data.ScaffoldedModels.Billing_Pay
            {
                Amount = proof.Amount,
                Date_Of_Opreation = proof.PaymentDate,
                Notes = string.IsNullOrWhiteSpace(proof.Notes)
                    ? $"Approved from payment proof #{proof.Id}"
                    : proof.Notes,
                Custmor_Id = proof.CustomerId
            };

            _context.Billing_Pays.Add(payment);
            await _context.SaveChangesAsync();
            proof.BillingPaymentId = payment.Id;
        }

        await _context.SaveChangesAsync();

        if (proof.BillingPaymentId.HasValue && request.Status == "Approved")
        {
            await _inAppNotificationService.NotifyCustomerPaymentRecordedAsync(proof.CustomerId, proof.BillingPaymentId.Value, proof.Amount, proof.PaymentDate, HttpContext.RequestAborted);
        }

        await _inAppNotificationService.NotifyPaymentProofReviewedAsync(caseCode, proof.Id, proof.Amount, approved: request.Status == "Approved", HttpContext.RequestAborted);

        return Ok(await MapPaymentProofAsync(proof));
    }

    [HttpGet("{caseCode}/notification-preferences")]
    public async Task<ActionResult<CustomerCaseNotificationPreferenceDto>> GetCaseNotificationPreference(int caseCode)
    {
        if (!await CanAccessCase(caseCode))
        {
            return Forbid();
        }

        var customer = await GetCurrentCustomerAsync();
        if (customer == null)
        {
            return Ok(new CustomerCaseNotificationPreferenceDto
            {
                CaseCode = caseCode,
                NotificationsEnabled = true
            });
        }

        var setting = await _context.CustomerCaseNotificationSettings
            .SingleOrDefaultAsync(item => item.CaseCode == caseCode && item.CustomerId == customer.Id);

        return Ok(new CustomerCaseNotificationPreferenceDto
        {
            CaseCode = caseCode,
            NotificationsEnabled = setting?.NotificationsEnabled ?? true
        });
    }

    [HttpPut("{caseCode}/notification-preferences")]
    public async Task<ActionResult<CustomerCaseNotificationPreferenceDto>> UpdateCaseNotificationPreference(int caseCode, [FromBody] UpdateCustomerCaseNotificationPreferenceRequest request)
    {
        if (!await CanAccessCase(caseCode))
        {
            return Forbid();
        }

        var customer = await GetCurrentCustomerAsync();
        if (customer == null)
        {
            return Forbid();
        }

        var setting = await _context.CustomerCaseNotificationSettings
            .SingleOrDefaultAsync(item => item.CaseCode == caseCode && item.CustomerId == customer.Id);

        if (setting == null)
        {
            setting = new LawyerSys.Data.ScaffoldedModels.CustomerCaseNotificationSetting
            {
                CaseCode = caseCode,
                CustomerId = customer.Id,
                NotificationsEnabled = request.NotificationsEnabled,
                UpdatedAtUtc = DateTime.UtcNow
            };
            _context.CustomerCaseNotificationSettings.Add(setting);
        }
        else
        {
            setting.NotificationsEnabled = request.NotificationsEnabled;
            setting.UpdatedAtUtc = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return Ok(new CustomerCaseNotificationPreferenceDto
        {
            CaseCode = caseCode,
            NotificationsEnabled = setting.NotificationsEnabled
        });
    }

    private async Task<CustomerRequestedDocumentDto> MapRequestedDocumentAsync(LawyerSys.Data.ScaffoldedModels.CustomerRequestedDocument entity)
    {
        var customerName = await _context.Customers
            .Where(item => item.Id == entity.CustomerId)
            .Select(item => item.Users.Full_Name ?? item.Users.User_Name)
            .FirstOrDefaultAsync() ?? string.Empty;

        var file = entity.UploadedFileId.HasValue
            ? await _context.Files.AsNoTracking().SingleOrDefaultAsync(item => item.Id == entity.UploadedFileId.Value)
            : null;

        return new CustomerRequestedDocumentDto
        {
            Id = entity.Id,
            CaseCode = entity.CaseCode,
            CustomerId = entity.CustomerId,
            CustomerName = customerName,
            Title = entity.Title,
            Description = entity.Description,
            DueDate = entity.DueDate,
            Status = entity.Status,
            RequestedByName = entity.RequestedByName,
            CustomerNotes = entity.CustomerNotes,
            ReviewNotes = entity.ReviewNotes,
            UploadedFileId = entity.UploadedFileId,
            UploadedFileCode = file?.Code ?? string.Empty,
            UploadedFilePath = file?.Path ?? string.Empty,
            RequestedAtUtc = entity.RequestedAtUtc,
            SubmittedAtUtc = entity.SubmittedAtUtc,
            ReviewedAtUtc = entity.ReviewedAtUtc
        };
    }

    private async Task<CustomerPaymentProofDto> MapPaymentProofAsync(LawyerSys.Data.ScaffoldedModels.CustomerPaymentProof entity)
    {
        var customerName = await _context.Customers
            .Where(item => item.Id == entity.CustomerId)
            .Select(item => item.Users.Full_Name ?? item.Users.User_Name)
            .FirstOrDefaultAsync() ?? string.Empty;

        var file = entity.ProofFileId.HasValue
            ? await _context.Files.AsNoTracking().SingleOrDefaultAsync(item => item.Id == entity.ProofFileId.Value)
            : null;

        return new CustomerPaymentProofDto
        {
            Id = entity.Id,
            CustomerId = entity.CustomerId,
            CaseCode = entity.CaseCode,
            CustomerName = customerName,
            Amount = entity.Amount,
            PaymentDate = entity.PaymentDate,
            Notes = entity.Notes,
            ProofFileId = entity.ProofFileId,
            ProofFileCode = file?.Code ?? string.Empty,
            ProofFilePath = file?.Path ?? string.Empty,
            Status = entity.Status,
            BillingPaymentId = entity.BillingPaymentId,
            ReviewNotes = entity.ReviewNotes,
            SubmittedAtUtc = entity.SubmittedAtUtc,
            ReviewedAtUtc = entity.ReviewedAtUtc
        };
    }

    private string ResolveSenderName()
    {
        return User.FindFirst("fullName")?.Value
            ?? _userContext.GetUserName()
            ?? "System";
    }

    private async Task<LawyerSys.Data.ScaffoldedModels.Customer?> GetCurrentCustomerAsync()
    {
        var userName = _userContext.GetUserName();
        if (string.IsNullOrWhiteSpace(userName))
        {
            return null;
        }

        return await _context.Customers
            .Include(item => item.Users)
            .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);
    }

    private async Task<bool> CanAccessCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin"))
        {
            return true;
        }

        var userName = _userContext.GetUserName();

        if (roles.Contains("Employee"))
        {
            var employee = await _context.Employees
                .Include(item => item.Users)
                .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);

            if (employee == null)
            {
                return false;
            }

            return await _context.Cases_Employees.AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employee.id);
        }

        if (roles.Contains("Customer"))
        {
            var customer = await GetCurrentCustomerAsync();
            if (customer == null)
            {
                return false;
            }

            return await _context.Custmors_Cases.AnyAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customer.Id);
        }

        return false;
    }

    private async Task<bool> CanModifyCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin"))
        {
            return true;
        }

        if (roles.Contains("Employee"))
        {
            var userName = _userContext.GetUserName();
            var employee = await _context.Employees
                .Include(item => item.Users)
                .FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == userName);

            if (employee == null)
            {
                return false;
            }

            return await _context.Cases_Employees.AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employee.id);
        }

        return false;
    }
}
