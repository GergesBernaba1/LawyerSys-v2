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
    public class CaseService : ICaseService
    {
        private readonly LegacyDbContext _context;
        private readonly IUserContext _userContext;
        private readonly IInAppNotificationService _inAppNotificationService;

        private static readonly Dictionary<CaseStatus, CaseStatus[]> AllowedStatusTransitions = new()
        {
            [CaseStatus.New] = new[] { CaseStatus.InProgress, CaseStatus.AwaitingHearing, CaseStatus.Closed },
            [CaseStatus.InProgress] = new[] { CaseStatus.AwaitingHearing, CaseStatus.Closed, CaseStatus.Won, CaseStatus.Lost },
            [CaseStatus.AwaitingHearing] = new[] { CaseStatus.InProgress, CaseStatus.Closed, CaseStatus.Won, CaseStatus.Lost },
            [CaseStatus.Closed] = new[] { CaseStatus.Won, CaseStatus.Lost, CaseStatus.InProgress },
            [CaseStatus.Won] = Array.Empty<CaseStatus>(),
            [CaseStatus.Lost] = Array.Empty<CaseStatus>()
        };

        public CaseService(
            LegacyDbContext context,
            IUserContext userContext,
            IInAppNotificationService inAppNotificationService)
        {
            _context = context;
            _userContext = userContext;
            _inAppNotificationService = inAppNotificationService;
        }

        public async Task<IEnumerable<CaseDto>> GetCasesAsync(string? search = null)
        {
            var cases = await GetCasesQuery(search).OrderBy(c => c.Code).ToListAsync();
            return cases.Select(MapToDto);
        }

        public async Task<PagedResult<CaseDto>> GetCasesAsync(int page, int pageSize, string? search)
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

            var query = GetCasesQuery(search);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Code)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<CaseDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        private IQueryable<Case> GetCasesQuery(string? search)
        {
            var rolesTask = _userContext.GetUserRolesAsync();
            rolesTask.Wait();
            var roles = rolesTask.Result;
            var isAdmin = roles.Contains("Admin");
            var isEmployee = roles.Contains("Employee");
            var isCustomer = roles.Contains("Customer");

            IQueryable<Case> query = _context.Cases;

            if (isCustomer && !isAdmin && !isEmployee)
            {
                var userName = _userContext.GetUserName();
                var customer = _context.Customers
                    .Include(c => c.Users)
                    .FirstOrDefault(c => c.Users != null && c.Users.User_Name == userName);

                if (customer == null)
                    return query.Where(_ => false);

                var caseCodes = _context.Custmors_Cases
                    .Where(cc => cc.Custmors_Id == customer.Id)
                    .Select(cc => cc.Case_Id)
                    .ToList();

                query = query.Where(c => caseCodes.Contains(c.Code));
            }
            else if (isEmployee && !isAdmin)
            {
                var userName = _userContext.GetUserName();
                var employee = _context.Employees
                    .Include(e => e.Users)
                    .FirstOrDefault(e => e.Users != null && e.Users.User_Name == userName);

                if (employee == null)
                    return query.Where(_ => false);

                var caseCodes = _context.Cases_Employees
                    .Where(ce => ce.Employee_Id == employee.id)
                    .Select(ce => ce.Case_Code)
                    .ToList();

                query = query.Where(c => caseCodes.Contains(c.Code));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(c => c.Code.ToString().Contains(s) || c.Invition_Type.Contains(s) || c.Notes.Contains(s));
            }

            return query;
        }

        public async Task<CaseDto?> GetCaseAsync(int code)
        {
            var caseEntity = await _context.Cases.FindAsync(code);
            return caseEntity == null ? null : MapToDto(caseEntity);
        }

        public async Task<CaseDto> CreateCaseAsync(CreateCaseDto dto)
        {
            if (await _context.Cases.AnyAsync(c => c.Code == dto.Code))
                throw new ArgumentException("Case code already exists");

            var caseEntity = new Case
            {
                Code = dto.Code,
                Invitions_Statment = dto.InvitionsStatment,
                Invition_Type = dto.InvitionType,
                Invition_Date = dto.InvitionDate,
                Total_Amount = dto.TotalAmount,
                Notes = dto.Notes ?? string.Empty,
                Status = (int)CaseStatus.New
            };

            _context.Cases.Add(caseEntity);
            _context.CaseStatusHistories.Add(new CaseStatusHistory
            {
                Case_Id = caseEntity.Code,
                OldStatus = (int)CaseStatus.New,
                NewStatus = (int)CaseStatus.New,
                ChangedBy = _userContext.GetUserName() ?? "System",
                ChangedAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();

            return MapToDto(caseEntity);
        }

        public async Task<CaseDto> UpdateCaseAsync(int code, UpdateCaseDto dto)
        {
            var caseEntity = await _context.Cases.FindAsync(code);
            if (caseEntity == null)
                throw new ArgumentException("Case not found");

            if (dto.InvitionsStatment != null) caseEntity.Invitions_Statment = dto.InvitionsStatment;
            if (dto.InvitionType != null) caseEntity.Invition_Type = dto.InvitionType;
            if (dto.InvitionDate.HasValue) caseEntity.Invition_Date = dto.InvitionDate.Value;
            if (dto.TotalAmount.HasValue) caseEntity.Total_Amount = dto.TotalAmount.Value;
            if (dto.Notes != null) caseEntity.Notes = dto.Notes;

            await _context.SaveChangesAsync();

            return MapToDto(caseEntity);
        }

        public async Task<bool> DeleteCaseAsync(int code)
        {
            var caseEntity = await _context.Cases.FindAsync(code);
            if (caseEntity == null)
                return false;

            _context.Cases.Remove(caseEntity);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> CanAccessCaseAsync(int caseCode)
        {
            var roles = await _userContext.GetUserRolesAsync();
            if (roles.Contains("Admin"))
                return true;

            var userName = _userContext.GetUserName();

            if (roles.Contains("Employee"))
            {
                var employee = await _context.Employees
                    .Include(e => e.Users)
                    .FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == userName);

                if (employee == null) return false;

                return await _context.Cases_Employees
                    .AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employee.id);
            }

            if (roles.Contains("Customer"))
            {
                var customer = await _context.Customers
                    .Include(c => c.Users)
                    .FirstOrDefaultAsync(c => c.Users != null && c.Users.User_Name == userName);

                if (customer == null) return false;

                return await _context.Custmors_Cases
                    .AnyAsync(cc => cc.Case_Id == caseCode && cc.Custmors_Id == customer.Id);
            }

            return false;
        }

        public async Task<bool> CanModifyCaseAsync(int caseCode)
        {
            var roles = await _userContext.GetUserRolesAsync();
            if (roles.Contains("Admin"))
                return true;

            if (roles.Contains("Employee"))
            {
                var userName = _userContext.GetUserName();
                var employee = await _context.Employees
                    .Include(e => e.Users)
                    .FirstOrDefaultAsync(e => e.Users != null && e.Users.User_Name == userName);

                if (employee == null) return false;

                return await _context.Cases_Employees
                    .AnyAsync(ce => ce.Case_Code == caseCode && ce.Employee_Id == employee.id);
            }

            return false;
        }

        public async Task AssignEmployeeAsync(int caseCode, int employeeId)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode);
            if (caseEntity == null)
                throw new ArgumentException("Case not found");

            var employee = await _context.Employees.FindAsync(employeeId);
            if (employee == null)
                throw new ArgumentException("Employee not found");

            var existing = _context.Cases_Employees.Where(ce => ce.Case_Code == caseCode);
            _context.Cases_Employees.RemoveRange(existing);

            var assign = new Cases_Employee { Case_Code = caseCode, Employee_Id = employee.id };
            _context.Cases_Employees.Add(assign);
            await _context.SaveChangesAsync();
        }

        public async Task UnassignEmployeeAsync(int caseCode)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == caseCode);
            if (caseEntity == null)
                throw new ArgumentException("Case not found");

            var existing = _context.Cases_Employees.Where(ce => ce.Case_Code == caseCode);
            _context.Cases_Employees.RemoveRange(existing);
            await _context.SaveChangesAsync();
        }

        public async Task<IEnumerable<CaseAssignmentDto>> GetAssignmentsAsync()
        {
            var assignments = await _context.Cases_Employees
                .Include(ce => ce.Employee)
                    .ThenInclude(e => e.Users)
                .Select(ce => new CaseAssignmentDto
                {
                    CaseCode = ce.Case_Code,
                    EmployeeId = ce.Employee_Id,
                    Employee = ce.Employee != null && ce.Employee.Users != null ? new UserDto
                    {
                        Id = ce.Employee.Users.Id,
                        FullName = ce.Employee.Users.Full_Name,
                        UserName = ce.Employee.Users.User_Name
                    } : null
                })
                .ToListAsync();

            return assignments;
        }

        public async Task<CaseDto> ChangeCaseStatusAsync(int code, string status)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
            if (caseEntity == null)
                throw new ArgumentException("Case not found");

            if (string.IsNullOrWhiteSpace(status))
                throw new ArgumentException("Status is required");

            if (!System.Enum.TryParse<CaseStatus>(status, true, out var newStatus))
                throw new ArgumentException("Invalid status value");

            var oldStatus = (CaseStatus)caseEntity.Status;
            if (oldStatus == newStatus)
                throw new ArgumentException("Case is already in this status");

            var allowedTargets = AllowedStatusTransitions.GetValueOrDefault(oldStatus, Array.Empty<CaseStatus>());
            if (!allowedTargets.Contains(newStatus))
            {
                var allowed = string.Join(", ", allowedTargets.Select(MapStatusLabel));
                throw new ArgumentException($"Invalid status transition from {MapStatusLabel(oldStatus)} to {MapStatusLabel(newStatus)}. Allowed: {allowed}");
            }

            caseEntity.Status = (int)newStatus;

            var history = new CaseStatusHistory
            {
                Case_Id = caseEntity.Code,
                OldStatus = (int)oldStatus,
                NewStatus = (int)newStatus,
                ChangedBy = _userContext.GetUserName(),
                ChangedAt = DateTime.UtcNow
            };

            _context.CaseStatusHistories.Add(history);
            await _context.SaveChangesAsync();
            await _inAppNotificationService.NotifyCaseStatusChangedAsync(code, oldStatus, newStatus);

            return MapToDto(caseEntity);
        }

        public Task<IEnumerable<object>> GetStatusOptionsAsync()
        {
            var options = Enum.GetValues<CaseStatus>()
                .Select(s => (object)new
                {
                    value = (int)s,
                    key = s.ToString(),
                    label = MapStatusLabel(s),
                    next = AllowedStatusTransitions.GetValueOrDefault(s, Array.Empty<CaseStatus>())
                        .Select(n => new { value = (int)n, key = n.ToString(), label = MapStatusLabel(n) })
                });

            return Task.FromResult(options.AsEnumerable());
        }

        public async Task<IEnumerable<CaseStatusHistoryDto>> GetStatusHistoryAsync(int code)
        {
            var exists = await _context.Cases.AnyAsync(c => c.Code == code);
            if (!exists)
                throw new ArgumentException("Case not found");

            var list = await _context.CaseStatusHistories
                .Where(h => h.Case_Id == code)
                .OrderByDescending(h => h.ChangedAt)
                .Select(h => new CaseStatusHistoryDto
                {
                    Id = h.Id,
                    CaseId = h.Case_Id,
                    OldStatus = (CaseStatus)h.OldStatus,
                    NewStatus = (CaseStatus)h.NewStatus,
                    ChangedBy = h.ChangedBy,
                    ChangedAt = h.ChangedAt
                })
                .ToListAsync();

            return list;
        }

        public async Task<CaseTimelineDto> GetCaseTimelineAsync(int code)
        {
            var caseEntity = await _context.Cases.FirstOrDefaultAsync(c => c.Code == code);
            if (caseEntity == null)
                throw new ArgumentException("Case not found");

            var events = new List<CaseTimelineEventDto>
            {
                new()
                {
                    Category = "Case",
                    OccurredAt = caseEntity.Invition_Date.ToDateTime(TimeOnly.MinValue),
                    Title = "Case Opened",
                    Description = $"Case type: {caseEntity.Invition_Type}"
                }
            };

            var hearings = await _context.Cases_Sitings
                .Include(cs => cs.Siting)
                .Where(cs => cs.Case_Code == code)
                .Select(cs => new
                {
                    cs.Siting_Id,
                    cs.Siting.Siting_Time,
                    cs.Siting.Judge_Name,
                    cs.Siting.Notes
                })
                .ToListAsync();

            events.AddRange(hearings.Select(h => new CaseTimelineEventDto
            {
                Category = "Hearing",
                OccurredAt = h.Siting_Time,
                Title = "Hearing Scheduled",
                Description = $"Judge: {h.Judge_Name}, Notes: {h.Notes}",
                EntityId = h.Siting_Id
            }));

            var customerIds = await _context.Custmors_Cases
                .Where(cc => cc.Case_Id == code)
                .Select(cc => cc.Custmors_Id)
                .Distinct()
                .ToListAsync();

            var documents = await _context.Judicial_Documents
                .Where(d => customerIds.Contains(d.Customers_Id))
                .Select(d => new
                {
                    d.Id,
                    d.Doc_Type,
                    d.Doc_Details
                })
                .ToListAsync();

            events.AddRange(documents.Select(d => new CaseTimelineEventDto
            {
                Category = "Document",
                OccurredAt = DateTime.UtcNow,
                Title = "Document Attached",
                Description = $"Type: {d.Doc_Type}, Details: {d.Doc_Details}",
                EntityId = d.Id
            }));

            var statusChanges = await _context.CaseStatusHistories
                .Where(h => h.Case_Id == code)
                .OrderBy(h => h.ChangedAt)
                .ToListAsync();

            events.AddRange(statusChanges.Select(s => new CaseTimelineEventDto
            {
                Category = "Status",
                OccurredAt = s.ChangedAt,
                Title = "Status Changed",
                Description = $"{MapStatusLabel((CaseStatus)s.OldStatus)} → {MapStatusLabel((CaseStatus)s.NewStatus)} by {s.ChangedBy ?? "Unknown"}",
                EntityId = s.Id
            }));

            var billingEvents = await _context.Billing_Pays
                .Where(p => customerIds.Contains(p.Custmor_Id))
                .OrderBy(p => p.Date_Of_Opreation)
                .Select(p => new
                {
                    p.Id,
                    p.Date_Of_Opreation,
                    p.Amount,
                    p.Notes
                })
                .ToListAsync();

            events.AddRange(billingEvents.Select(b => new CaseTimelineEventDto
            {
                Category = "Billing",
                OccurredAt = b.Date_Of_Opreation.ToDateTime(TimeOnly.MinValue),
                Title = "Payment Recorded",
                Description = $"Amount: {b.Amount}, Notes: {b.Notes}",
                EntityId = b.Id
            }));

            return new CaseTimelineDto
            {
                CaseCode = caseEntity.Code,
                CaseType = caseEntity.Invition_Type,
                Events = events.OrderBy(e => e.OccurredAt).ToList()
            };
        }

        private static CaseDto MapToDto(Case c) => new()
        {
            Id = c.Id,
            Code = c.Code,
            InvitionsStatment = c.Invitions_Statment,
            InvitionType = c.Invition_Type,
            InvitionDate = c.Invition_Date,
            TotalAmount = c.Total_Amount,
            Notes = c.Notes,
            Status = (CaseStatus)c.Status
        };

        private static string MapStatusLabel(CaseStatus status) => status switch
        {
            CaseStatus.New => "New",
            CaseStatus.InProgress => "In Progress",
            CaseStatus.AwaitingHearing => "Awaiting Hearing",
            CaseStatus.Closed => "Closed",
            CaseStatus.Won => "Won",
            CaseStatus.Lost => "Lost",
            _ => status.ToString()
        };
    }
}
