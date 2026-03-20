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
    public class BillingService : IBillingService
    {
        private readonly LegacyDbContext _context;
        private readonly IEmployeeAccessService _employeeAccessService;
        private readonly IInAppNotificationService _inAppNotificationService;

        public BillingService(
            LegacyDbContext context,
            IEmployeeAccessService employeeAccessService,
            IInAppNotificationService inAppNotificationService)
        {
            _context = context;
            _employeeAccessService = employeeAccessService;
            _inAppNotificationService = inAppNotificationService;
        }

        // ========== PAYMENTS ==========

        public async Task<IEnumerable<BillingPayDto>> GetPaymentsAsync(string? search = null)
        {
            var payments = await GetPaymentsQuery(search).OrderBy(x => x.Id).ToListAsync();
            return payments.Select(MapPayToDto);
        }

        public async Task<PagedResult<BillingPayDto>> GetPaymentsAsync(int page, int pageSize, string? search)
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

            var query = GetPaymentsQuery(search);
            var total = await query.CountAsync();
            var items = await query.OrderBy(x => x.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<BillingPayDto>
            {
                Items = items.Select(MapPayToDto),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        private IQueryable<Billing_Pay> GetPaymentsQuery(string? search)
        {
            IQueryable<Billing_Pay> query = _context.Billing_Pays
                .Include(p => p.Custmor).ThenInclude(c => c.Users);

            if (_employeeAccessService.IsCurrentUserEmployeeOnlyAsync().Result)
            {
                var assignedCustomerIds = _employeeAccessService.GetAssignedCustomerIdsAsync().Result;
                query = assignedCustomerIds.Length == 0
                    ? query.Where(_ => false)
                    : query.Where(p => assignedCustomerIds.Contains(p.Custmor_Id));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(p =>
                    p.Id.ToString().Contains(s) ||
                    p.Amount.ToString().Contains(s) ||
                    p.Notes.Contains(s) ||
                    (p.Custmor != null && p.Custmor.Users != null && p.Custmor.Users.Full_Name.Contains(s)));
            }

            return query;
        }

        public async Task<BillingPayDto?> GetPaymentAsync(int id)
        {
            var payment = await _context.Billing_Pays
                .Include(p => p.Custmor).ThenInclude(c => c.Users)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null)
                return null;

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync() &&
                !await _employeeAccessService.CanAccessCustomerAsync(payment.Custmor_Id))
                return null;

            return MapPayToDto(payment);
        }

        public async Task<BillingPayDto> CreatePaymentAsync(CreateBillingPayDto dto)
        {
            var customer = await _context.Customers.FindAsync(dto.CustomerId);
            if (customer == null)
                throw new ArgumentException("Customer not found");

            var payment = new Billing_Pay
            {
                Amount = dto.Amount,
                Date_Of_Opreation = dto.DateOfOperation,
                Notes = dto.Notes ?? string.Empty,
                Custmor_Id = dto.CustomerId
            };

            _context.Billing_Pays.Add(payment);
            await _context.SaveChangesAsync();

            await _context.Entry(payment).Reference(p => p.Custmor).LoadAsync();
            await _context.Entry(payment.Custmor).Reference(c => c.Users).LoadAsync();

            await _inAppNotificationService.NotifyCustomerPaymentRecordedAsync(
                payment.Custmor_Id, payment.Id, payment.Amount, payment.Date_Of_Opreation, default);

            return MapPayToDto(payment);
        }

        public async Task<BillingPayDto> UpdatePaymentAsync(int id, UpdateBillingPayDto dto)
        {
            var payment = await _context.Billing_Pays
                .Include(p => p.Custmor).ThenInclude(c => c.Users)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null)
                throw new ArgumentException("Payment not found");

            if (dto.Amount.HasValue) payment.Amount = dto.Amount.Value;
            if (dto.DateOfOperation.HasValue) payment.Date_Of_Opreation = dto.DateOfOperation.Value;
            if (dto.Notes != null) payment.Notes = dto.Notes;

            await _context.SaveChangesAsync();
            return MapPayToDto(payment);
        }

        public async Task<bool> DeletePaymentAsync(int id)
        {
            var payment = await _context.Billing_Pays.FindAsync(id);
            if (payment == null)
                return false;

            _context.Billing_Pays.Remove(payment);
            await _context.SaveChangesAsync();
            return true;
        }

        // ========== RECEIPTS ==========

        public async Task<IEnumerable<BillingReceiptDto>> GetReceiptsAsync(string? search = null)
        {
            var receipts = await GetReceiptsQuery(search).OrderBy(x => x.Id).ToListAsync();
            return receipts.Select(MapReceiptToDto);
        }

        public async Task<PagedResult<BillingReceiptDto>> GetReceiptsAsync(int page, int pageSize, string? search)
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

            var query = GetReceiptsQuery(search);
            var total = await query.CountAsync();
            var items = await query.OrderBy(x => x.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<BillingReceiptDto>
            {
                Items = items.Select(MapReceiptToDto),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        private IQueryable<Billing_Receipt> GetReceiptsQuery(string? search)
        {
            IQueryable<Billing_Receipt> query = _context.Billing_Receipts;

            if (_employeeAccessService.IsCurrentUserEmployeeOnlyAsync().Result)
            {
                var employeeId = _employeeAccessService.GetCurrentEmployeeIdAsync().Result;
                query = employeeId.HasValue
                    ? query.Where(r => r.Employee_Id == employeeId.Value)
                    : query.Where(_ => false);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(r =>
                    r.Id.ToString().Contains(s) ||
                    r.Amount.ToString().Contains(s) ||
                    r.Notes.Contains(s) ||
                    r.Employee_Id.ToString().Contains(s));
            }

            return query;
        }

        public async Task<BillingReceiptDto?> GetReceiptAsync(int id)
        {
            var receipt = await _context.Billing_Receipts.FindAsync(id);
            if (receipt == null)
                return null;

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
                if (!employeeId.HasValue || receipt.Employee_Id != employeeId.Value)
                    return null;
            }

            return MapReceiptToDto(receipt);
        }

        public async Task<BillingReceiptDto> CreateReceiptAsync(CreateBillingReceiptDto dto)
        {
            var receipt = new Billing_Receipt
            {
                Amount = dto.Amount,
                Date_Of_Opreation = dto.DateOfOperation,
                Notes = dto.Notes ?? string.Empty,
                Employee_Id = dto.EmployeeId
            };

            _context.Billing_Receipts.Add(receipt);
            await _context.SaveChangesAsync();
            return MapReceiptToDto(receipt);
        }

        public async Task<BillingReceiptDto> UpdateReceiptAsync(int id, UpdateBillingReceiptDto dto)
        {
            var receipt = await _context.Billing_Receipts.FindAsync(id);
            if (receipt == null)
                throw new ArgumentException("Receipt not found");

            if (dto.Amount.HasValue) receipt.Amount = dto.Amount.Value;
            if (dto.DateOfOperation.HasValue) receipt.Date_Of_Opreation = dto.DateOfOperation.Value;
            if (dto.Notes != null) receipt.Notes = dto.Notes;

            await _context.SaveChangesAsync();
            return MapReceiptToDto(receipt);
        }

        public async Task<bool> DeleteReceiptAsync(int id)
        {
            var receipt = await _context.Billing_Receipts.FindAsync(id);
            if (receipt == null)
                return false;

            _context.Billing_Receipts.Remove(receipt);
            await _context.SaveChangesAsync();
            return true;
        }

        // ========== SUMMARY ==========

        public async Task<object> GetBillingSummaryAsync(int? customerId, DateOnly? fromDate, DateOnly? toDate)
        {
            var paymentsQuery = _context.Billing_Pays.AsQueryable();
            var receiptsQuery = _context.Billing_Receipts.AsQueryable();

            if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
            {
                var assignedCustomerIds = await _employeeAccessService.GetAssignedCustomerIdsAsync();
                var employeeId = await _employeeAccessService.GetCurrentEmployeeIdAsync();
                paymentsQuery = assignedCustomerIds.Length == 0
                    ? paymentsQuery.Where(_ => false)
                    : paymentsQuery.Where(p => assignedCustomerIds.Contains(p.Custmor_Id));
                receiptsQuery = employeeId.HasValue
                    ? receiptsQuery.Where(r => r.Employee_Id == employeeId.Value)
                    : receiptsQuery.Where(_ => false);
            }

            if (customerId.HasValue)
                paymentsQuery = paymentsQuery.Where(p => p.Custmor_Id == customerId);

            if (fromDate.HasValue)
            {
                paymentsQuery = paymentsQuery.Where(p => p.Date_Of_Opreation >= fromDate);
                receiptsQuery = receiptsQuery.Where(r => r.Date_Of_Opreation >= fromDate);
            }

            if (toDate.HasValue)
            {
                paymentsQuery = paymentsQuery.Where(p => p.Date_Of_Opreation <= toDate);
                receiptsQuery = receiptsQuery.Where(r => r.Date_Of_Opreation <= toDate);
            }

            var totalPayments = await paymentsQuery.SumAsync(p => p.Amount);
            var totalReceipts = await receiptsQuery.SumAsync(r => r.Amount);
            var paymentCount = await paymentsQuery.CountAsync();
            var receiptCount = await receiptsQuery.CountAsync();

            return new
            {
                TotalPayments = totalPayments,
                TotalReceipts = totalReceipts,
                PaymentCount = paymentCount,
                ReceiptCount = receiptCount,
                Balance = totalReceipts - totalPayments
            };
        }

        private static BillingPayDto MapPayToDto(Billing_Pay p) => new()
        {
            Id = p.Id,
            Amount = p.Amount,
            DateOfOperation = p.Date_Of_Opreation,
            Notes = p.Notes,
            CustomerId = p.Custmor_Id,
            CustomerName = p.Custmor?.Users?.Full_Name
        };

        private static BillingReceiptDto MapReceiptToDto(Billing_Receipt r) => new()
        {
            Id = r.Id,
            Amount = r.Amount,
            DateOfOperation = r.Date_Of_Opreation,
            Notes = r.Notes,
            EmployeeId = r.Employee_Id
        };
    }
}
