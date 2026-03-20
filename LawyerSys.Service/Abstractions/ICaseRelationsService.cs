namespace LawyerSys.Services.CaseRelations;

public interface ICaseRelationsService
{
    Task<ServiceResult<object>> GetCaseCustomersAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddCustomerToCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveCustomerFromCaseAsync(int caseCode, int customerId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseContendersAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddContenderToCaseAsync(int caseCode, int contenderId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveContenderFromCaseAsync(int caseCode, int contenderId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseCourtsAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddCourtToCaseAsync(int caseCode, int courtId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveCourtFromCaseAsync(int caseCode, int courtId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseEmployeesAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddEmployeeToCaseAsync(int caseCode, int employeeId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveEmployeeFromCaseAsync(int caseCode, int employeeId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseSitingsAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddSitingToCaseAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveSitingFromCaseAsync(int caseCode, int sitingId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseFilesAsync(int caseCode, CancellationToken cancellationToken = default);
    Task<ServiceResult<int>> AddFileToCaseAsync(int caseCode, int fileId, CancellationToken cancellationToken = default);
    Task<ServiceResult<bool>> RemoveFileFromCaseAsync(int caseCode, int fileId, CancellationToken cancellationToken = default);
    Task<ServiceResult<object>> GetCaseFullDetailsAsync(int caseCode, CancellationToken cancellationToken = default);
}
