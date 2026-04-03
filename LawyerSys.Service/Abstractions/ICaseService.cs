using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface ICaseService
    {
        // Case CRUD
        Task<IEnumerable<CaseDto>> GetCasesAsync(string? search = null);
        Task<PagedResult<CaseDto>> GetCasesAsync(int page, int pageSize, string? search);
        Task<CaseDto?> GetCaseAsync(int code);
        Task<CaseDto> CreateCaseAsync(CreateCaseDto dto);
        Task<CaseDto> UpdateCaseAsync(int code, UpdateCaseDto dto);
        Task<bool> DeleteCaseAsync(int code);

        // Case access control
        Task<bool> CanAccessCaseAsync(int caseCode);
        Task<bool> CanModifyCaseAsync(int caseCode);

        // Employee assignment
        Task AssignEmployeeAsync(int caseCode, int employeeId);
        Task UnassignEmployeeAsync(int caseCode);
        Task<IEnumerable<CaseAssignmentDto>> GetAssignmentsAsync();

        // Status management
        Task<CaseDto> ChangeCaseStatusAsync(int code, string status);
        Task<IEnumerable<object>> GetStatusOptionsAsync();
        Task<IEnumerable<CaseStatusHistoryDto>> GetStatusHistoryAsync(int code);
        Task<IEnumerable<CaseCourtHistoryDto>> GetCourtHistoryAsync(int code);

        // Timeline
        Task<CaseTimelineDto> GetCaseTimelineAsync(int code);
    }
}
