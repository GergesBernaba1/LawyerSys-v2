using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.Services.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace LawyerSys.Services.CaseRelations;

public sealed class CaseRelationsService : ICaseRelationsService
{
    private readonly LegacyDbContext _legacyDbContext;
    private readonly IInAppNotificationService _notificationService;
    private readonly IServiceOperationContextFactory _operationContextFactory;
    private readonly ILogger<CaseRelationsService> _logger;

    public CaseRelationsService(
        LegacyDbContext legacyDbContext,
        IInAppNotificationService notificationService,
        IServiceOperationContextFactory operationContextFactory,
        ILogger<CaseRelationsService> logger)
    {
        _legacyDbContext = legacyDbContext;
        _notificationService = notificationService;
        _operationContextFactory = operationContextFactory;
        _logger = logger;
    }

    public async Task<ServiceResult<object>> GetCaseCustomersAsync(int caseCode, CancellationToken cancellationToken = default)
        => ServiceResult<object>.Success(await _legacyDbContext.Custmors_Cases
            .Include(item => item.Custmors).ThenInclude(item => item.Users)
            .Where(item => item.Case_Id == caseCode)
            .Select(item => (object)new { Id = item.Id, CustomerId = item.Custmors_Id, CustomerName = item.Custmors!.Users!.Full_Name })
            .ToListAsync(cancellationToken));

    public async Task<ServiceResult<int>> AddCustomerToCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default)
    {
        if (await _legacyDbContext.Custmors_Cases.AnyAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customerId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "Customer", "case");

        var relation = new Custmors_Case { Case_Id = caseCode, Custmors_Id = customerId };
        _legacyDbContext.Custmors_Cases.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        await _notificationService.NotifyCustomerAddedToCaseAsync(caseCode, customerId);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveCustomerFromCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default)
    {
        var relation = await _legacyDbContext.Custmors_Cases.FirstOrDefaultAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customerId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Custmors_Cases.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _notificationService.NotifyCustomerRemovedFromCaseAsync(caseCode, customerId, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to publish customer-remove notification for case {CaseCode} and customer {CustomerId}", caseCode, customerId);
        }

        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseContendersAsync(int caseCode, CancellationToken cancellationToken = default)
        => ServiceResult<object>.Success(await _legacyDbContext.Cases_Contenders
            .Include(item => item.Contender)
            .Where(item => item.Case_Id == caseCode)
            .Select(item => (object)new { Id = item.Id, ContenderId = item.Contender_Id, ContenderName = item.Contender!.Full_Name })
            .ToListAsync(cancellationToken));

    public async Task<ServiceResult<int>> AddContenderToCaseAsync(int caseCode, int contenderId, CancellationToken cancellationToken = default)
    {
        if (await _legacyDbContext.Cases_Contenders.AnyAsync(item => item.Case_Id == caseCode && item.Contender_Id == contenderId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "Contender", "case");

        var relation = new Cases_Contender { Case_Id = caseCode, Contender_Id = contenderId };
        _legacyDbContext.Cases_Contenders.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveContenderFromCaseAsync(int caseCode, int contenderId, CancellationToken cancellationToken = default)
    {
        var relation = await _legacyDbContext.Cases_Contenders.FirstOrDefaultAsync(item => item.Case_Id == caseCode && item.Contender_Id == contenderId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Cases_Contenders.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseCourtsAsync(int caseCode, CancellationToken cancellationToken = default)
        => ServiceResult<object>.Success(await _legacyDbContext.Cases_Courts
            .Include(item => item.Court)
            .Where(item => item.Case_Code == caseCode)
            .Select(item => (object)new { Id = item.Id, CourtId = item.Court_Id, CourtName = item.Court!.Name })
            .ToListAsync(cancellationToken));

    public async Task<ServiceResult<int>> AddCourtToCaseAsync(int caseCode, int courtId, CancellationToken cancellationToken = default)
    {
        if (await _legacyDbContext.Cases_Courts.AnyAsync(item => item.Case_Code == caseCode && item.Court_Id == courtId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "Court", "case");

        var courtName = await _legacyDbContext.Courts
            .Where(court => court.Id == courtId)
            .Select(court => court.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;

        var relation = new Cases_Court { Case_Code = caseCode, Court_Id = courtId };
        _legacyDbContext.Cases_Courts.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);

        await RecordCaseCourtHistoryAsync(
            caseCode,
            oldCourtId: null,
            oldCourtName: null,
            newCourtId: courtId,
            newCourtName: courtName,
            changeType: "Added",
            cancellationToken);

        await _notificationService.NotifyCaseCourtAddedAsync(caseCode, courtId, courtName, cancellationToken);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveCourtFromCaseAsync(int caseCode, int courtId, CancellationToken cancellationToken = default)
    {
        var relation = await _legacyDbContext.Cases_Courts.FirstOrDefaultAsync(item => item.Case_Code == caseCode && item.Court_Id == courtId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Cases_Courts.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);

        var courtName = await _legacyDbContext.Courts
            .Where(court => court.Id == courtId)
            .Select(court => court.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;

        await RecordCaseCourtHistoryAsync(
            caseCode,
            oldCourtId: courtId,
            oldCourtName: courtName,
            newCourtId: null,
            newCourtName: null,
            changeType: "Removed",
            cancellationToken);

        await _notificationService.NotifyCaseCourtRemovedAsync(caseCode, courtId, courtName, cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<bool>> ChangeCourtForCaseAsync(int caseCode, int oldCourtId, int newCourtId, CancellationToken cancellationToken = default)
    {
        if (oldCourtId == newCourtId)
            return ServiceResult<bool>.Validation("CourtChangeSame");

        var oldRelation = await _legacyDbContext.Cases_Courts
            .FirstOrDefaultAsync(item => item.Case_Code == caseCode && item.Court_Id == oldCourtId, cancellationToken);
        if (oldRelation == null)
            return ServiceResult<bool>.NotFound("Relation");

        var alreadyLinked = await _legacyDbContext.Cases_Courts
            .AnyAsync(item => item.Case_Code == caseCode && item.Court_Id == newCourtId, cancellationToken);
        if (alreadyLinked)
            return ServiceResult<bool>.Conflict("AlreadyLinked", "Court", "case");

        var oldCourtName = await _legacyDbContext.Courts
            .Where(court => court.Id == oldCourtId)
            .Select(court => court.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;

        var newCourtName = await _legacyDbContext.Courts
            .Where(court => court.Id == newCourtId)
            .Select(court => court.Name)
            .FirstOrDefaultAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(newCourtName))
            return ServiceResult<bool>.NotFound("Court");

        _legacyDbContext.Cases_Courts.Remove(oldRelation);
        _legacyDbContext.Cases_Courts.Add(new Cases_Court { Case_Code = caseCode, Court_Id = newCourtId });
        await _legacyDbContext.SaveChangesAsync(cancellationToken);

        await RecordCaseCourtHistoryAsync(
            caseCode,
            oldCourtId: oldCourtId,
            oldCourtName: oldCourtName,
            newCourtId: newCourtId,
            newCourtName: newCourtName,
            changeType: "Changed",
            cancellationToken);

        await _notificationService.NotifyCaseCourtChangedAsync(
            caseCode,
            oldCourtId,
            oldCourtName,
            newCourtId,
            newCourtName,
            cancellationToken);

        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseEmployeesAsync(int caseCode, CancellationToken cancellationToken = default)
        => ServiceResult<object>.Success(await _legacyDbContext.Cases_Employees
            .Include(item => item.Employee).ThenInclude(item => item.Users)
            .Where(item => item.Case_Code == caseCode)
            .Select(item => (object)new { Id = item.Id, EmployeeId = item.Employee_Id, EmployeeName = item.Employee!.Users!.Full_Name })
            .ToListAsync(cancellationToken));

    public async Task<ServiceResult<int>> AddEmployeeToCaseAsync(int caseCode, int employeeId, CancellationToken cancellationToken = default)
    {
        if (await _legacyDbContext.Cases_Employees.AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employeeId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "Employee", "case");

        var relation = new Cases_Employee { Case_Code = caseCode, Employee_Id = employeeId };
        _legacyDbContext.Cases_Employees.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        await _notificationService.NotifyEmployeeCaseAssignedAsync(employeeId, caseCode, cancellationToken);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveEmployeeFromCaseAsync(int caseCode, int employeeId, CancellationToken cancellationToken = default)
    {
        var relation = await _legacyDbContext.Cases_Employees.FirstOrDefaultAsync(item => item.Case_Code == caseCode && item.Employee_Id == employeeId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Cases_Employees.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseSitingsAsync(int caseCode, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<object>.Forbidden("Forbidden");

        var payload = await _legacyDbContext.Cases_Sitings
            .Include(item => item.Siting)
            .Where(item => item.Case_Code == caseCode)
            .Select(item => (object)new { Id = item.Id, SitingId = item.Siting_Id, SitingDate = item.Siting!.Siting_Date, JudgeName = item.Siting.Judge_Name })
            .ToListAsync(cancellationToken);
        return ServiceResult<object>.Success(payload);
    }

    public async Task<ServiceResult<int>> AddSitingToCaseAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<int>.Forbidden("Forbidden");
        if (await _legacyDbContext.Cases_Sitings.AnyAsync(item => item.Case_Code == caseCode && item.Siting_Id == sitingId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "Siting", "case");

        var relation = new Cases_Siting { Case_Code = caseCode, Siting_Id = sitingId };
        _legacyDbContext.Cases_Sitings.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveSitingFromCaseAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<bool>.Forbidden("Forbidden");

        var relation = await _legacyDbContext.Cases_Sitings.FirstOrDefaultAsync(item => item.Case_Code == caseCode && item.Siting_Id == sitingId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Cases_Sitings.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseFilesAsync(int caseCode, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<object>.Forbidden("Forbidden");

        var payload = await _legacyDbContext.Cases_Files
            .Include(item => item.File)
            .Where(item => item.Case_Id == caseCode)
            .Select(item => (object)new { Id = item.Id, FileId = item.File_Id, FilePath = item.File!.Path, FileCode = item.File.Code })
            .ToListAsync(cancellationToken);
        return ServiceResult<object>.Success(payload);
    }

    public async Task<ServiceResult<int>> AddFileToCaseAsync(int caseCode, int fileId, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<int>.Forbidden("Forbidden");
        if (await _legacyDbContext.Cases_Files.AnyAsync(item => item.Case_Id == caseCode && item.File_Id == fileId, cancellationToken))
            return ServiceResult<int>.Conflict("AlreadyLinked", "File", "case");

        var relation = new Cases_File { Case_Id = caseCode, File_Id = fileId };
        _legacyDbContext.Cases_Files.Add(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        var file = await _legacyDbContext.Files.FindAsync(new object[] { fileId }, cancellationToken);
        await _notificationService.NotifyCaseFileAddedAsync(caseCode, fileId, file?.Code ?? string.Empty, cancellationToken);
        return ServiceResult<int>.Success(relation.Id);
    }

    public async Task<ServiceResult<bool>> RemoveFileFromCaseAsync(int caseCode, int fileId, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<bool>.Forbidden("Forbidden");

        var relation = await _legacyDbContext.Cases_Files.FirstOrDefaultAsync(item => item.Case_Id == caseCode && item.File_Id == fileId, cancellationToken);
        if (relation == null)
            return ServiceResult<bool>.NotFound("Relation");

        _legacyDbContext.Cases_Files.Remove(relation);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
        return ServiceResult<bool>.Success(true);
    }

    public async Task<ServiceResult<object>> GetCaseFullDetailsAsync(int caseCode, CancellationToken cancellationToken = default)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var caseEntity = await _legacyDbContext.Cases.FirstOrDefaultAsync(item => item.Code == caseCode, cancellationToken);
        if (caseEntity == null)
            return ServiceResult<object>.NotFound("Case");
        if (!await CanAccessCaseAsync(caseCode, operationContext, cancellationToken))
            return ServiceResult<object>.Forbidden("Forbidden");

        var payload = new
        {
            Case = new
            {
                caseEntity.Id,
                caseEntity.Code,
                InvitionsStatment = caseEntity.Invitions_Statment,
                InvitionType = caseEntity.Invition_Type,
                InvitionDate = caseEntity.Invition_Date,
                TotalAmount = caseEntity.Total_Amount,
                caseEntity.Notes,
                Status = caseEntity.Status
            }
        };

        return ServiceResult<object>.Success(payload);
    }

    private async Task<bool> CanAccessCaseAsync(int caseCode, ServiceOperationContext context, CancellationToken cancellationToken)
    {
        if (context.IsInRole("Admin"))
            return true;

        if (context.IsInRole("Employee"))
        {
            var employee = await _legacyDbContext.Employees.Include(item => item.Users).FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == context.UserName, cancellationToken);
            return employee != null && await _legacyDbContext.Cases_Employees.AnyAsync(item => item.Case_Code == caseCode && item.Employee_Id == employee.id, cancellationToken);
        }

        if (context.IsInRole("Customer"))
        {
            var customer = await _legacyDbContext.Customers.Include(item => item.Users).FirstOrDefaultAsync(item => item.Users != null && item.Users.User_Name == context.UserName, cancellationToken);
            return customer != null && await _legacyDbContext.Custmors_Cases.AnyAsync(item => item.Case_Id == caseCode && item.Custmors_Id == customer.Id, cancellationToken);
        }

        return false;
    }

    private async Task RecordCaseCourtHistoryAsync(
        int caseCode,
        int? oldCourtId,
        string? oldCourtName,
        int? newCourtId,
        string? newCourtName,
        string changeType,
        CancellationToken cancellationToken)
    {
        var operationContext = await _operationContextFactory.CreateAsync(cancellationToken);
        var history = new LawyerSys.Data.ScaffoldedModels.CaseCourtHistory
        {
            Case_Id = caseCode,
            OldCourt_Id = oldCourtId,
            NewCourt_Id = newCourtId,
            OldCourt_Name = oldCourtName,
            NewCourt_Name = newCourtName,
            ChangeType = changeType,
            ChangedBy = operationContext.UserName ?? "System",
            ChangedAt = DateTime.UtcNow
        };

        _legacyDbContext.CaseCourtHistories.Add(history);
        await _legacyDbContext.SaveChangesAsync(cancellationToken);
    }
}
