using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Services.Notifications;

namespace LawyerSys.Services
{
    public class SitingService : ISitingService
    {
        private readonly LegacyDbContext _context;
        private readonly IEmployeeAccessService _employeeAccessService;
        private readonly IInAppNotificationService _inAppNotificationService;

        public SitingService(
            LegacyDbContext context,
            IEmployeeAccessService employeeAccessService,
            IInAppNotificationService inAppNotificationService)
        {
            _context = context;
            _employeeAccessService = employeeAccessService;
            _inAppNotificationService = inAppNotificationService;
        }

        public async Task<IEnumerable<SitingDto>> GetSitingsAsync(string? search = null)
        {
            var query = await GetSitingsQueryAsync(search);
            var sitings = await query.OrderBy(st => st.Id).ToListAsync();
            return sitings.Select(MapToDto);
        }

        public async Task<PagedResult<SitingDto>> GetSitingsAsync(int page, int pageSize, string? search)
        {
            // Clamp pagination parameters to avoid runtime exceptions and ensure consistent behavior
            page = Math.Max(1, page);
            const int MaxPageSize = 100;
            if (pageSize <= 0)
            {
                pageSize = 10;
            }
            else if (pageSize > MaxPageSize)
            {
                pageSize = MaxPageSize;
            }

            var query = await GetSitingsQueryAsync(search);
            var total = await query.CountAsync();
            var items = await query.OrderBy(st => st.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<SitingDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        private async Task<IQueryable<Siting>> GetSitingsQueryAsync(string? search)
        {
            IQueryable<Siting> query = _context.Sitings.Include(st => st.Cases_Sitings);

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var assignedCaseCodes = await _employeeAccessService.GetAssignedCaseCodesAsync();
                query = assignedCaseCodes.Length == 0
                    ? query.Where(_ => false)
                    : query.Where(st => st.Cases_Sitings.Any(cs => assignedCaseCodes.Contains(cs.Case_Code)));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(st => st.Judge_Name.Contains(s) || st.Notes.Contains(s));
            }

            return query;
        }

        public async Task<SitingDto?> GetSitingAsync(int id)
        {
            var siting = await _context.Sitings.Include(st => st.Cases_Sitings).FirstOrDefaultAsync(st => st.Id == id);
            if (siting == null)
                return null;

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
                if (!await CanAccessAllCasesAsync(caseCodes))
                    throw new UnauthorizedAccessException();
            }

            return MapToDto(siting);
        }

        public async Task<SitingDto> CreateSitingAsync(CreateSitingDto dto)
        {
            if (dto.CaseCode.HasValue)
            {
                var caseExists = await _context.Cases.AnyAsync(c => c.Code == dto.CaseCode.Value);
                if (!caseExists)
                    throw new InvalidOperationException("CaseNotFoundForSiting");
            }

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                if (!dto.CaseCode.HasValue)
                    throw new InvalidOperationException("EmployeesMustLinkSiting");

                if (!await _employeeAccessService.CanAccessCaseAsync(dto.CaseCode.Value))
                    throw new UnauthorizedAccessException();
            }

            var siting = new Siting
            {
                Siting_Time = dto.SitingTime,
                Siting_Date = dto.SitingDate,
                Siting_Notification = dto.SitingNotification,
                Judge_Name = dto.JudgeName,
                Notes = dto.Notes ?? string.Empty
            };

            _context.Sitings.Add(siting);
            await _context.SaveChangesAsync();

            if (dto.CaseCode.HasValue)
            {
                var exists = await _context.Cases_Sitings.AnyAsync(cs => cs.Case_Code == dto.CaseCode.Value && cs.Siting_Id == siting.Id);
                if (!exists)
                {
                    _context.Cases_Sitings.Add(new Cases_Siting { Case_Code = dto.CaseCode.Value, Siting_Id = siting.Id });
                    await _context.SaveChangesAsync();
                }

                await _inAppNotificationService.NotifyCaseSitingScheduledAsync(dto.CaseCode.Value, siting.Id, siting.Siting_Time, siting.Judge_Name, default);
            }

            await _context.Entry(siting).Collection(st => st.Cases_Sitings).LoadAsync();
            return MapToDto(siting);
        }

        public async Task<SitingDto> UpdateSitingAsync(int id, UpdateSitingDto dto)
        {
            var siting = await _context.Sitings.Include(item => item.Cases_Sitings).FirstOrDefaultAsync(item => item.Id == id);
            if (siting == null)
                throw new ArgumentException("Siting not found");

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
                if (!await CanAccessAllCasesAsync(caseCodes))
                    throw new UnauthorizedAccessException();
            }

            if (dto.SitingTime.HasValue) siting.Siting_Time = dto.SitingTime.Value;
            if (dto.SitingDate.HasValue) siting.Siting_Date = dto.SitingDate.Value;
            if (dto.SitingNotification.HasValue) siting.Siting_Notification = dto.SitingNotification.Value;
            if (dto.JudgeName != null) siting.Judge_Name = dto.JudgeName;
            if (dto.Notes != null) siting.Notes = dto.Notes;

            await _context.SaveChangesAsync();

            foreach (var caseCode in siting.Cases_Sitings.Select(item => item.Case_Code).Distinct())
                await _inAppNotificationService.NotifyCaseSitingUpdatedAsync(caseCode, siting.Id, siting.Siting_Time, siting.Judge_Name, default);

            return MapToDto(siting);
        }

        public async Task<bool> DeleteSitingAsync(int id)
        {
            var siting = await _context.Sitings.Include(item => item.Cases_Sitings).FirstOrDefaultAsync(item => item.Id == id);
            if (siting == null)
                return false;

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var caseCodesToValidate = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToArray();
                if (!await CanAccessAllCasesAsync(caseCodesToValidate))
                    throw new UnauthorizedAccessException();
            }

            var caseCodes = siting.Cases_Sitings.Select(item => item.Case_Code).Distinct().ToList();
            _context.Sitings.Remove(siting);
            await _context.SaveChangesAsync();

            foreach (var caseCode in caseCodes)
                await _inAppNotificationService.NotifyCaseSitingCancelledAsync(caseCode, id, default);

            return true;
        }

        private async Task<bool> CanAccessAllCasesAsync(IEnumerable<int> caseCodes)
        {
            var distinct = caseCodes.Distinct().ToArray();
            if (distinct.Length == 0) return false;
            foreach (var code in distinct)
                if (!await _employeeAccessService.CanAccessCaseAsync(code)) return false;
            return true;
        }

        private static SitingDto MapToDto(Siting s) => new()
        {
            Id = s.Id,
            CaseCode = s.Cases_Sitings.OrderBy(cs => cs.Id).Select(cs => (int?)cs.Case_Code).FirstOrDefault(),
            SitingTime = s.Siting_Time,
            SitingDate = s.Siting_Date,
            SitingNotification = s.Siting_Notification,
            JudgeName = s.Judge_Name,
            Notes = s.Notes
        };
    }
}
