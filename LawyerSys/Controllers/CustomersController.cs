using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
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
    private static readonly string[] AllowedImageExtensions = new[] { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" };
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;

    private readonly ICustomerService _customerService;
    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public CustomersController(ICustomerService customerService, LegacyDbContext context, IWebHostEnvironment env, IStringLocalizer<SharedResource> localizer)
    {
        _customerService = customerService;
        _context = context;
        _env = env;
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

    // POST: api/customers/{id}/profile-image
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{id}/profile-image")]
    public async Task<ActionResult<CustomerDto>> UploadProfileImage(int id, [FromForm] IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = _localizer["NoFileUploaded"].Value });
        if (file.Length > MaxImageSizeBytes)
            return BadRequest(new { message = "Image size must be 5 MB or less." });

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedImageExtensions.Contains(extension))
            return BadRequest(new { message = "Unsupported image type." });

        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (customer == null)
            return this.EntityNotFound<CustomerDto>(_localizer, "Customer");
        if (customer.Users == null)
            return BadRequest(new { message = "Customer does not have a linked user." });

        var storedPath = await SaveProfileImageAsync(file, "customers", extension);
        var previousPath = customer.Users.Profile_Image_Path;
        customer.Users.Profile_Image_Path = storedPath;
        await _context.SaveChangesAsync();
        DeletePhysicalFileIfExists(previousPath);

        var updated = await _customerService.GetCustomerAsync(id);
        if (updated == null)
            return this.EntityNotFound<CustomerDto>(_localizer, "Customer");

        return Ok(updated);
    }

    // GET: api/customers/{id}/profile-image
    [HttpGet("{id}/profile-image")]
    public async Task<IActionResult> GetProfileImage(int id)
    {
        var customer = await _context.Customers
            .Include(c => c.Users)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (customer == null)
            return this.EntityNotFound(_localizer, "Customer");
        if (string.IsNullOrWhiteSpace(customer.Users?.Profile_Image_Path))
            return this.EntityNotFound(_localizer, "File");

        if (!TryResolveTrustedFilePath(customer.Users.Profile_Image_Path, out var fullPath))
            return this.EntityNotFound(_localizer, "File");
        if (!System.IO.File.Exists(fullPath))
            return this.EntityNotFound(_localizer, "File");

        var stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return File(stream, GetContentType(fullPath));
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

    private void DeletePhysicalFileIfExists(string? path)
    {
        if (!TryResolveTrustedFilePath(path, out var fullPath))
            return;
        if (System.IO.File.Exists(fullPath))
            System.IO.File.Delete(fullPath);
    }

    private async Task<string> SaveProfileImageAsync(IFormFile file, string folderName, string extension)
    {
        var folderPath = Path.Combine(_env.ContentRootPath, "Uploads", "profiles", folderName);
        if (!Directory.Exists(folderPath))
            Directory.CreateDirectory(folderPath);

        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(folderPath, fileName);
        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/Uploads/profiles/{folderName}/{fileName}";
    }

    private bool TryResolveTrustedFilePath(string? path, out string fullPath)
    {
        fullPath = string.Empty;
        if (string.IsNullOrWhiteSpace(path))
            return false;

        var normalized = path.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var uploadsRoot = Path.GetFullPath(Path.Combine(_env.ContentRootPath, "Uploads"));
        var resolved = Path.GetFullPath(Path.Combine(_env.ContentRootPath, normalized));
        if (!resolved.StartsWith(uploadsRoot, StringComparison.OrdinalIgnoreCase))
            return false;

        fullPath = resolved;
        return true;
    }

    private static string GetContentType(string path) => Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".png" => "image/png",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".gif" => "image/gif",
        ".bmp" => "image/bmp",
        ".webp" => "image/webp",
        _ => "application/octet-stream"
    };
}
