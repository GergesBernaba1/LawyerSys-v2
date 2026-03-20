using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.Services.Notifications;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/cases")]
public class CaseRelationsController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly IUserContext _userContext;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CaseRelationsController(
        LegacyDbContext context,
        IInAppNotificationService inAppNotificationService,
        IUserContext userContext,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _inAppNotificationService = inAppNotificationService;
        _userContext = userContext;
        _localizer = localizer;
    }

    // ========== CASE - CUSTOMER RELATIONS ==========

    [HttpGet("{caseCode}/customers")]
    public async Task<ActionResult> GetCaseCustomers(int caseCode)
    {
        var relations = await _context.Custmors_Cases
            .Include(cc => cc.Custmors).ThenInclude(c => c.Users)
            .Where(cc => cc.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, CustomerId = r.Custmors_Id, CustomerName = r.Custmors?.Users?.Full_Name }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> AddCustomerToCase(int caseCode, int customerId)
    {
        if (await _context.Custmors_Cases.AnyAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customerId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "Customer", "case"].Value });

        var relation = new Custmors_Case { Case_Id = caseCode, Custmors_Id = customerId };
        _context.Custmors_Cases.Add(relation);
        await _context.SaveChangesAsync();
        await _inAppNotificationService.NotifyCustomerAddedToCaseAsync(caseCode, customerId);
        return Ok(new { message = _localizer["AddedTo", "Customer", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/customers/{customerId}")]
    public async Task<ActionResult> RemoveCustomerFromCase(int caseCode, int customerId)
    {
        var relation = await _context.Custmors_Cases.FirstOrDefaultAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customerId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Custmors_Cases.Remove(relation);
        await _context.SaveChangesAsync();
        await _inAppNotificationService.NotifyCustomerRemovedFromCaseAsync(caseCode, customerId);
        return Ok(new { message = _localizer["RemovedFrom", "Customer", "case"].Value });
    }

    // ========== CASE - CONTENDER RELATIONS ==========

    [HttpGet("{caseCode}/contenders")]
    public async Task<ActionResult> GetCaseContenders(int caseCode)
    {
        var relations = await _context.Cases_Contenders
            .Include(cc => cc.Contender)
            .Where(cc => cc.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, ContenderId = r.Contender_Id, ContenderName = r.Contender?.Full_Name }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> AddContenderToCase(int caseCode, int contenderId)
    {
        if (await _context.Cases_Contenders.AnyAsync(cc => cc.Case_Id == caseCode && cc.Contender_Id == contenderId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "Contender", "case"].Value });

        var relation = new Cases_Contender { Case_Id = caseCode, Contender_Id = contenderId };
        _context.Cases_Contenders.Add(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["AddedTo", "Contender", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/contenders/{contenderId}")]
    public async Task<ActionResult> RemoveContenderFromCase(int caseCode, int contenderId)
    {
        var relation = await _context.Cases_Contenders.FirstOrDefaultAsync(cc => cc.Case_Id == caseCode && cc.Contender_Id == contenderId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Cases_Contenders.Remove(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["RemovedFrom", "Contender", "case"].Value });
    }

    // ========== CASE - COURT RELATIONS ==========

    [HttpGet("{caseCode}/courts")]
    public async Task<ActionResult> GetCaseCourts(int caseCode)
    {
        var relations = await _context.Cases_Courts
            .Include(cc => cc.Court)
            .Where(cc => cc.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, CourtId = r.Court_Id, CourtName = r.Court?.Name }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> AddCourtToCase(int caseCode, int courtId)
    {
        if (await _context.Cases_Courts.AnyAsync(cc => cc.Case_Code == caseCode && cc.Court_Id == courtId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "Court", "case"].Value });

        var relation = new Cases_Court { Case_Code = caseCode, Court_Id = courtId };
        _context.Cases_Courts.Add(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["AddedTo", "Court", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/courts/{courtId}")]
    public async Task<ActionResult> RemoveCourtFromCase(int caseCode, int courtId)
    {
        var relation = await _context.Cases_Courts.FirstOrDefaultAsync(cc => cc.Case_Code == caseCode && cc.Court_Id == courtId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Cases_Courts.Remove(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["RemovedFrom", "Court", "case"].Value });
    }

    // ========== CASE - EMPLOYEE RELATIONS ==========

    [HttpGet("{caseCode}/employees")]
    public async Task<ActionResult> GetCaseEmployees(int caseCode)
    {
        var relations = await _context.Cases_Employees
            .Include(ce => ce.Employee).ThenInclude(e => e.Users)
            .Where(ce => ce.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, EmployeeId = r.Employee_Id, EmployeeName = r.Employee?.Users?.Full_Name }));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> AddEmployeeToCase(int caseCode, int employeeId)
    {
        if (await _context.Cases_Employees.AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employeeId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "Employee", "case"].Value });

        var relation = new Cases_Employee { Case_Code = caseCode, Employee_Id = employeeId };
        _context.Cases_Employees.Add(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["AddedTo", "Employee", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{caseCode}/employees/{employeeId}")]
    public async Task<ActionResult> RemoveEmployeeFromCase(int caseCode, int employeeId)
    {
        var relation = await _context.Cases_Employees.FirstOrDefaultAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employeeId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Cases_Employees.Remove(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["RemovedFrom", "Employee", "case"].Value });
    }

    // ========== CASE - SITING RELATIONS ==========

    [HttpGet("{caseCode}/sitings")]
    public async Task<ActionResult> GetCaseSitings(int caseCode)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        var relations = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Case_Code == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, SitingId = r.Siting_Id, SitingDate = r.Siting?.Siting_Date, JudgeName = r.Siting?.Judge_Name }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> AddSitingToCase(int caseCode, int sitingId)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        if (await _context.Cases_Sitings.AnyAsync(cs => cs.Case_Code == caseCode && cs.Siting_Id == sitingId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "Siting", "case"].Value });

        var relation = new Cases_Siting { Case_Code = caseCode, Siting_Id = sitingId };
        _context.Cases_Sitings.Add(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["AddedTo", "Siting", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/sitings/{sitingId}")]
    public async Task<ActionResult> RemoveSitingFromCase(int caseCode, int sitingId)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        var relation = await _context.Cases_Sitings.FirstOrDefaultAsync(cs => cs.Case_Code == caseCode && cs.Siting_Id == sitingId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Cases_Sitings.Remove(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["RemovedFrom", "Siting", "case"].Value });
    }

    // ========== CASE - FILE RELATIONS ==========

    [HttpGet("{caseCode}/files")]
    public async Task<ActionResult> GetCaseFiles(int caseCode)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        var relations = await _context.Cases_Files
            .Include(cf => cf.File)
            .Where(cf => cf.Case_Id == caseCode)
            .ToListAsync();

        return Ok(relations.Select(r => new { Id = r.Id, FileId = r.File_Id, FilePath = r.File?.Path, FileCode = r.File?.Code }));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> AddFileToCase(int caseCode, int fileId)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        if (await _context.Cases_Files.AnyAsync(cf => cf.Case_Id == caseCode && cf.File_Id == fileId))
            return BadRequest(new { message = _localizer["AlreadyLinked", "File", "case"].Value });

        var relation = new Cases_File { Case_Id = caseCode, File_Id = fileId };
        _context.Cases_Files.Add(relation);
        await _context.SaveChangesAsync();

        var file = await _context.Files.FindAsync(fileId);
        await _inAppNotificationService.NotifyCaseFileAddedAsync(caseCode, fileId, file?.Code ?? string.Empty, HttpContext.RequestAborted);
        return Ok(new { message = _localizer["AddedTo", "File", "case"].Value, id = relation.Id });
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{caseCode}/files/{fileId}")]
    public async Task<ActionResult> RemoveFileFromCase(int caseCode, int fileId)
    {
        if (!await CanAccessCase(caseCode)) return Forbid();

        var relation = await _context.Cases_Files.FirstOrDefaultAsync(cf => cf.Case_Id == caseCode && cf.File_Id == fileId);
        if (relation == null)
            return this.EntityNotFound(_localizer, "Relation");

        _context.Cases_Files.Remove(relation);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["RemovedFrom", "File", "case"].Value });
    }

    // ========== FULL CASE DETAILS ==========

    [HttpGet("{caseCode}/full")]
    public async Task<ActionResult> GetCaseFullDetails(int caseCode)
    {
        var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode);
        if (caseEntity == null)
            return this.EntityNotFound(_localizer, "Case");
        if (!await CanAccessCase(caseCode))
            return Forbid();

        var roles = await _userContext.GetUserRolesAsync();
        var isAdmin = roles.Contains("Admin");
        var isEmployee = roles.Contains("Employee");
        var isCustomerOnly = roles.Contains("Customer") && !isAdmin && !isEmployee;
        var currentCustomerId = isCustomerOnly
            ? await _context.Customers
                .Include(c => c.Users)
                .Where(c => c.Users != null && c.Users.User_Name == _userContext.GetUserName())
                .Select(c => (int?)c.Id)
                .FirstOrDefaultAsync()
            : null;

        var accessibleCustomerIds = currentCustomerId.HasValue
            ? new[] { currentCustomerId.Value }
            : await _context.Custmors_Cases
                .Where(cc => cc.Case_Id == caseCode)
                .Select(cc => cc.Custmors_Id)
                .Distinct()
                .ToArrayAsync();

        var customers = await _context.Custmors_Cases
            .Include(cc => cc.Custmors).ThenInclude(c => c.Users)
            .Where(cc => cc.Case_Id == caseCode && accessibleCustomerIds.Contains(cc.Custmors_Id))
            .Select(cc => new { cc.Custmors.Id, cc.Custmors.Users.Full_Name })
            .ToListAsync();

        var contenders = await _context.Cases_Contenders
            .Include(cc => cc.Contender)
            .Where(cc => cc.Case_Id == caseCode)
            .Select(cc => new { cc.Contender.Id, cc.Contender.Full_Name })
            .ToListAsync();

        var courts = await _context.Cases_Courts
            .Include(cc => cc.Court)
            .Where(cc => cc.Case_Code == caseCode)
            .Select(cc => new { cc.Court.Id, cc.Court.Name })
            .ToListAsync();

        var employees = await _context.Cases_Employees
            .Include(ce => ce.Employee).ThenInclude(e => e.Users)
            .Where(ce => ce.Case_Code == caseCode)
            .Select(ce => new { ce.Employee.id, ce.Employee.Users.Full_Name })
            .ToListAsync();

        var sitings = await _context.Cases_Sitings
            .Include(cs => cs.Siting)
            .Where(cs => cs.Case_Code == caseCode)
            .Select(cs => new { cs.Siting.Id, cs.Siting.Siting_Date, cs.Siting.Judge_Name })
            .ToListAsync();

        var files = await _context.Cases_Files
            .Include(cf => cf.File)
            .Where(cf => cf.Case_Id == caseCode)
            .Select(cf => new { cf.File.Id, cf.File.Path, cf.File.Code })
            .ToListAsync();

        var statusHistory = await _context.CaseStatusHistories
            .Where(h => h.Case_Id == caseCode)
            .OrderByDescending(h => h.ChangedAt)
            .Select(h => new { h.Id, h.OldStatus, h.NewStatus, h.ChangedBy, h.ChangedAt })
            .ToListAsync();

        var documents = await _context.Judicial_Documents
            .Where(item => accessibleCustomerIds.Contains(item.Customers_Id))
            .OrderByDescending(item => item.Id)
            .Select(item => new { item.Id, DocType = item.Doc_Type, DocNum = item.Doc_Num, DocDetails = item.Doc_Details, item.Notes })
            .ToListAsync();

        var billingPayments = await _context.Billing_Pays
            .Where(item => accessibleCustomerIds.Contains(item.Custmor_Id))
            .OrderByDescending(item => item.Date_Of_Opreation)
            .Select(item => new { item.Id, Amount = item.Amount, DateOfOperation = item.Date_Of_Opreation, item.Notes, CustomerId = item.Custmor_Id })
            .ToListAsync();

        var requestedDocuments = await _context.CustomerRequestedDocuments
            .Where(item => item.CaseCode == caseCode && accessibleCustomerIds.Contains(item.CustomerId))
            .OrderByDescending(item => item.RequestedAtUtc)
            .Select(item => new
            {
                item.Id, item.CaseCode, CustomerId = item.CustomerId,
                CustomerName = _context.Customers.Where(c => c.Id == item.CustomerId).Select(c => c.Users.Full_Name ?? c.Users.User_Name).FirstOrDefault(),
                item.Title, item.Description, item.DueDate, item.Status, item.RequestedByName,
                item.CustomerNotes, item.ReviewNotes, item.UploadedFileId,
                UploadedFileCode = item.UploadedFileId.HasValue ? _context.Files.Where(f => f.Id == item.UploadedFileId.Value).Select(f => f.Code).FirstOrDefault() : string.Empty,
                UploadedFilePath = item.UploadedFileId.HasValue ? _context.Files.Where(f => f.Id == item.UploadedFileId.Value).Select(f => f.Path).FirstOrDefault() : string.Empty,
                item.RequestedAtUtc, item.SubmittedAtUtc, item.ReviewedAtUtc
            })
            .ToListAsync();

        var paymentProofs = await _context.CustomerPaymentProofs
            .Where(item => item.CaseCode == caseCode && accessibleCustomerIds.Contains(item.CustomerId))
            .OrderByDescending(item => item.SubmittedAtUtc)
            .Select(item => new
            {
                item.Id, item.CustomerId,
                CustomerName = _context.Customers.Where(c => c.Id == item.CustomerId).Select(c => c.Users.Full_Name ?? c.Users.User_Name).FirstOrDefault(),
                item.Amount, item.PaymentDate, item.Notes, item.ProofFileId,
                ProofFileCode = item.ProofFileId.HasValue ? _context.Files.Where(f => f.Id == item.ProofFileId.Value).Select(f => f.Code).FirstOrDefault() : string.Empty,
                ProofFilePath = item.ProofFileId.HasValue ? _context.Files.Where(f => f.Id == item.ProofFileId.Value).Select(f => f.Path).FirstOrDefault() : string.Empty,
                item.Status, item.BillingPaymentId, item.ReviewNotes, item.SubmittedAtUtc, item.ReviewedAtUtc
            })
            .ToListAsync();

        return Ok(new
        {
            Case = new
            {
                caseEntity.Id, caseEntity.Code,
                InvitionsStatment = caseEntity.Invitions_Statment,
                InvitionType = caseEntity.Invition_Type,
                InvitionDate = caseEntity.Invition_Date,
                TotalAmount = caseEntity.Total_Amount,
                caseEntity.Notes,
                Status = caseEntity.Status
            },
            Customers = customers, Contenders = contenders, Courts = courts, Employees = employees,
            Sitings = sitings, Files = files, StatusHistory = statusHistory, Documents = documents,
            BillingPayments = billingPayments, RequestedDocuments = requestedDocuments, PaymentProofs = paymentProofs
        });
    }

    private async Task<bool> CanAccessCase(int caseCode)
    {
        var roles = await _userContext.GetUserRolesAsync();
        if (roles.Contains("Admin")) return true;

        var userName = _userContext.GetUserName();

        if (roles.Contains("Employee"))
        {
            var employee = await _context.Employees.Include(e => e.Users).FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == userName);
            if (employee == null) return false;
            return await _context.Cases_Employees.AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employee.id);
        }

        if (roles.Contains("Customer"))
        {
            var customer = await _context.Customers.Include(c => c.Users).FirstOrDefaultAsync(c => c.Users != null && c.Users.User_Name == userName);
            if (customer == null) return false;
            return await _context.Custmors_Cases.AnyAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customer.Id);
        }

        return false;
    }
}
