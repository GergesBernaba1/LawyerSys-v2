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
public class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CustomersController(ICustomerService customerService, IStringLocalizer<SharedResource> localizer)
    {
        _customerService = customerService;
        _localizer = localizer;
    }

    // GET: api/customers
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CustomerDto>>> GetCustomers([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _customerService.GetCustomersAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var dtos = (await _customerService.GetCustomersAsync()).ToList();
        return Ok(dtos);
    }

    // GET: api/customers/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<CustomerDto>> GetCustomer(int id)
    {
        var dto = await _customerService.GetCustomerAsync(id);
        if (dto == null) return this.EntityNotFound<CustomerDto>(_localizer, "Customer");
        return Ok(dto);
    }

    // GET: api/customers/{id}/profile
    [HttpGet("{id}/profile")]
    public async Task<ActionResult<CustomerProfileDto>> GetCustomerProfile(int id)
    {
        var dto = await _customerService.GetCustomerProfileAsync(id);
        if (dto == null) return this.EntityNotFound<CustomerProfileDto>(_localizer, "Customer");
        return Ok(dto);
    }

    // POST: api/customers
    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<CustomerDto>> CreateCustomer([FromBody] CreateCustomerDto createDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var dto = await _customerService.CreateCustomerAsync(createDto);
            return CreatedAtAction(nameof(GetCustomer), new { id = dto.Id }, dto);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/customers/withuser - Create customer with new user
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("withuser")]
    public async Task<ActionResult<CustomerDto>> CreateCustomerWithUser([FromBody] CreateCustomerWithUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var (customer, tempCredentials) = await _customerService.CreateCustomerWithUserAsync(dto);
            return CreatedAtAction(nameof(GetCustomer), new { id = customer.Id }, new { customer = customer, tempCredentials = new { userName = tempCredentials.UserName, password = tempCredentials.Password } });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // PUT: api/customers/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCustomer(int id, [FromBody] UpdateCustomerDto dto)
    {
        try
        {
            var updated = await _customerService.UpdateCustomerAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/customers/{id}/send-password-reset-email
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{id}/send-password-reset-email")]
    public async Task<IActionResult> SendPasswordResetEmail(int id)
    {
        try
        {
            await _customerService.SendPasswordResetEmailAsync(id);
            return Ok(new { message = "Password reset email sent" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // DELETE: api/customers/{id}
    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCustomer(int id)
    {
        var ok = await _customerService.DeleteCustomerAsync(id);
        if (!ok) return this.EntityNotFound(_localizer, "Customer");
        return Ok(new { message = _localizer["CustomerDeleted"].Value });
    }
}
