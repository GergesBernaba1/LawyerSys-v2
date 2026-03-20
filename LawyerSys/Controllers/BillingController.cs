using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.DTOs;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BillingController : ControllerBase
{
    private readonly IBillingService _billingService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public BillingController(IBillingService billingService, IStringLocalizer<SharedResource> localizer)
    {
        _billingService = billingService;
        _localizer = localizer;
    }

    // ========== PAYMENTS ==========

    [HttpGet("payments")]
    public async Task<ActionResult<IEnumerable<BillingPayDto>>> GetPayments([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _billingService.GetPaymentsAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var payments = await _billingService.GetPaymentsAsync(search);
        return Ok(payments);
    }

    [HttpGet("payments/{id}")]
    public async Task<ActionResult<BillingPayDto>> GetPayment(int id)
    {
        var payment = await _billingService.GetPaymentAsync(id);
        if (payment == null)
            return this.EntityNotFound<BillingPayDto>(_localizer, "Payment");

        return Ok(payment);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("payments")]
    public async Task<ActionResult<BillingPayDto>> CreatePayment([FromBody] CreateBillingPayDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _billingService.CreatePaymentAsync(dto);
            return CreatedAtAction(nameof(GetPayment), new { id = created.Id }, created);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("payments/{id}")]
    public async Task<IActionResult> UpdatePayment(int id, [FromBody] UpdateBillingPayDto dto)
    {
        try
        {
            var updated = await _billingService.UpdatePaymentAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Payment");
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("payments/{id}")]
    public async Task<IActionResult> DeletePayment(int id)
    {
        var deleted = await _billingService.DeletePaymentAsync(id);
        if (!deleted)
            return this.EntityNotFound(_localizer, "Payment");

        return Ok(new { message = _localizer["PaymentDeleted"].Value });
    }

    // ========== RECEIPTS ==========

    [HttpGet("receipts")]
    public async Task<ActionResult<IEnumerable<BillingReceiptDto>>> GetReceipts([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _billingService.GetReceiptsAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var receipts = await _billingService.GetReceiptsAsync(search);
        return Ok(receipts);
    }

    [HttpGet("receipts/{id}")]
    public async Task<ActionResult<BillingReceiptDto>> GetReceipt(int id)
    {
        var receipt = await _billingService.GetReceiptAsync(id);
        if (receipt == null)
            return this.EntityNotFound<BillingReceiptDto>(_localizer, "Receipt");

        return Ok(receipt);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("receipts")]
    public async Task<ActionResult<BillingReceiptDto>> CreateReceipt([FromBody] CreateBillingReceiptDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _billingService.CreateReceiptAsync(dto);
            return CreatedAtAction(nameof(GetReceipt), new { id = created.Id }, created);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("receipts/{id}")]
    public async Task<IActionResult> UpdateReceipt(int id, [FromBody] UpdateBillingReceiptDto dto)
    {
        try
        {
            var updated = await _billingService.UpdateReceiptAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException)
        {
            return this.EntityNotFound(_localizer, "Receipt");
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("receipts/{id}")]
    public async Task<IActionResult> DeleteReceipt(int id)
    {
        var deleted = await _billingService.DeleteReceiptAsync(id);
        if (!deleted)
            return this.EntityNotFound(_localizer, "Receipt");

        return Ok(new { message = _localizer["ReceiptDeleted"].Value });
    }

    // ========== SUMMARY ==========

    [HttpGet("summary")]
    public async Task<ActionResult> GetBillingSummary([FromQuery] int? customerId, [FromQuery] DateOnly? fromDate, [FromQuery] DateOnly? toDate)
    {
        var summary = await _billingService.GetBillingSummaryAsync(customerId, fromDate, toDate);
        return Ok(summary);
    }
}
