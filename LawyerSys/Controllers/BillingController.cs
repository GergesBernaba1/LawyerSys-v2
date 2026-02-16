using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BillingController : ControllerBase
{
    private readonly LegacyDbContext _context;

    public BillingController(LegacyDbContext context)
    {
        _context = context;
    }

    // ========== PAYMENTS ==========

    [HttpGet("payments")]
    public async Task<ActionResult<IEnumerable<BillingPayDto>>> GetPayments()
    {
        var payments = await _context.Billing_Pays
            .Include(p => p.Custmor)
                .ThenInclude(c => c.Users)
            .ToListAsync();
        return Ok(payments.Select(MapPayToDto));
    }

    [HttpGet("payments/{id}")]
    public async Task<ActionResult<BillingPayDto>> GetPayment(int id)
    {
        var payment = await _context.Billing_Pays
            .Include(p => p.Custmor)
                .ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(p => p.Id == id);

        if (payment == null)
            return NotFound(new { message = "Payment not found" });

        return Ok(MapPayToDto(payment));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("payments")]
    public async Task<ActionResult<BillingPayDto>> CreatePayment([FromBody] CreateBillingPayDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var customer = await _context.Customers.FindAsync(dto.CustomerId);
        if (customer == null)
            return BadRequest(new { message = "Customer not found" });

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

        return CreatedAtAction(nameof(GetPayment), new { id = payment.Id }, MapPayToDto(payment));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("payments/{id}")]
    public async Task<IActionResult> UpdatePayment(int id, [FromBody] UpdateBillingPayDto dto)
    {
        var payment = await _context.Billing_Pays
            .Include(p => p.Custmor)
                .ThenInclude(c => c.Users)
            .FirstOrDefaultAsync(p => p.Id == id);

        if (payment == null)
            return NotFound(new { message = "Payment not found" });

        if (dto.Amount.HasValue) payment.Amount = dto.Amount.Value;
        if (dto.DateOfOperation.HasValue) payment.Date_Of_Opreation = dto.DateOfOperation.Value;
        if (dto.Notes != null) payment.Notes = dto.Notes;

        await _context.SaveChangesAsync();
        return Ok(MapPayToDto(payment));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("payments/{id}")]
    public async Task<IActionResult> DeletePayment(int id)
    {
        var payment = await _context.Billing_Pays.FindAsync(id);
        if (payment == null)
            return NotFound(new { message = "Payment not found" });

        _context.Billing_Pays.Remove(payment);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Payment deleted" });
    }

    // ========== RECEIPTS ==========

    [HttpGet("receipts")]
    public async Task<ActionResult<IEnumerable<BillingReceiptDto>>> GetReceipts()
    {
        var receipts = await _context.Billing_Receipts.ToListAsync();
        return Ok(receipts.Select(MapReceiptToDto));
    }

    [HttpGet("receipts/{id}")]
    public async Task<ActionResult<BillingReceiptDto>> GetReceipt(int id)
    {
        var receipt = await _context.Billing_Receipts.FindAsync(id);
        if (receipt == null)
            return NotFound(new { message = "Receipt not found" });

        return Ok(MapReceiptToDto(receipt));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("receipts")]
    public async Task<ActionResult<BillingReceiptDto>> CreateReceipt([FromBody] CreateBillingReceiptDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var receipt = new Billing_Receipt
        {
            Amount = dto.Amount,
            Date_Of_Opreation = dto.DateOfOperation,
            Notes = dto.Notes ?? string.Empty,
            Employee_Id = dto.EmployeeId
        };

        _context.Billing_Receipts.Add(receipt);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetReceipt), new { id = receipt.Id }, MapReceiptToDto(receipt));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("receipts/{id}")]
    public async Task<IActionResult> UpdateReceipt(int id, [FromBody] UpdateBillingReceiptDto dto)
    {
        var receipt = await _context.Billing_Receipts.FindAsync(id);
        if (receipt == null)
            return NotFound(new { message = "Receipt not found" });

        if (dto.Amount.HasValue) receipt.Amount = dto.Amount.Value;
        if (dto.DateOfOperation.HasValue) receipt.Date_Of_Opreation = dto.DateOfOperation.Value;
        if (dto.Notes != null) receipt.Notes = dto.Notes;

        await _context.SaveChangesAsync();
        return Ok(MapReceiptToDto(receipt));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("receipts/{id}")]
    public async Task<IActionResult> DeleteReceipt(int id)
    {
        var receipt = await _context.Billing_Receipts.FindAsync(id);
        if (receipt == null)
            return NotFound(new { message = "Receipt not found" });

        _context.Billing_Receipts.Remove(receipt);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Receipt deleted" });
    }

    // ========== REPORTS ==========

    [HttpGet("summary")]
    public async Task<ActionResult> GetBillingSummary([FromQuery] int? customerId, [FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate)
    {
        var paymentsQuery = _context.Billing_Pays.AsQueryable();
        var receiptsQuery = _context.Billing_Receipts.AsQueryable();

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

        return Ok(new
        {
            TotalPayments = totalPayments,
            TotalReceipts = totalReceipts,
            PaymentCount = paymentCount,
            ReceiptCount = receiptCount,
            Balance = totalReceipts - totalPayments
        });
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
