using System.Collections.Generic;
using System.Threading.Tasks;
using LawyerSys.DTOs;

namespace LawyerSys.Services
{
    public interface IBillingService
    {
        // Payments
        Task<IEnumerable<BillingPayDto>> GetPaymentsAsync(string? search = null);
        Task<PagedResult<BillingPayDto>> GetPaymentsAsync(int page, int pageSize, string? search);
        Task<BillingPayDto?> GetPaymentAsync(int id);
        Task<BillingPayDto> CreatePaymentAsync(CreateBillingPayDto dto);
        Task<BillingPayDto> UpdatePaymentAsync(int id, UpdateBillingPayDto dto);
        Task<bool> DeletePaymentAsync(int id);

        // Receipts
        Task<IEnumerable<BillingReceiptDto>> GetReceiptsAsync(string? search = null);
        Task<PagedResult<BillingReceiptDto>> GetReceiptsAsync(int page, int pageSize, string? search);
        Task<BillingReceiptDto?> GetReceiptAsync(int id);
        Task<BillingReceiptDto> CreateReceiptAsync(CreateBillingReceiptDto dto);
        Task<BillingReceiptDto> UpdateReceiptAsync(int id, UpdateBillingReceiptDto dto);
        Task<bool> DeleteReceiptAsync(int id);

        // Summary
        Task<object> GetBillingSummaryAsync(int? customerId, DateOnly? fromDate, DateOnly? toDate);
    }
}
