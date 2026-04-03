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
public class EmployeesController : ControllerBase
{
    private static readonly string[] AllowedImageExtensions = new[] { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" };
    private const long MaxImageSizeBytes = 5 * 1024 * 1024;

    private readonly IEmployeeService _employeeService;
    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public EmployeesController(IEmployeeService employeeService, LegacyDbContext context, IWebHostEnvironment env, IStringLocalizer<SharedResource> localizer)
    {
        _employeeService = employeeService;
        _context = context;
        _env = env;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<EmployeeDto>>> GetEmployees([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        if (page.HasValue && pageSize.HasValue)
        {
            var safePage = Math.Max(1, page.Value);
            var paged = await _employeeService.GetEmployeesAsync(safePage, pageSize.Value, search);
            return Ok(paged);
        }

        var dtos = (await _employeeService.GetEmployeesAsync()).ToList();
        return Ok(dtos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<EmployeeDto>> GetEmployee(int id)
    {
        var dto = await _employeeService.GetEmployeeAsync(id);
        if (dto == null) return this.EntityNotFound<EmployeeDto>(_localizer, "Employee");
        return Ok(dto);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost]
    public async Task<ActionResult<EmployeeDto>> CreateEmployee([FromBody] CreateEmployeeDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var created = await _employeeService.CreateEmployeeAsync(dto);
            return CreatedAtAction(nameof(GetEmployee), new { id = created.Id }, created);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("withuser")]
    public async Task<ActionResult<EmployeeDto>> CreateEmployeeWithUser([FromBody] CreateEmployeeWithUserDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var (employee, tempCredentials) = await _employeeService.CreateEmployeeWithUserAsync(dto);
            return CreatedAtAction(nameof(GetEmployee), new { id = employee.Id }, new { employee, tempCredentials = new { userName = tempCredentials.UserName, password = tempCredentials.Password } });
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

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEmployee(int id, [FromBody] UpdateEmployeeDto dto)
    {
        try
        {
            var updated = await _employeeService.UpdateEmployeeAsync(id, dto);
            return Ok(updated);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // POST: api/employees/{id}/profile-image
    [Authorize(Policy = "AdminOnly")]
    [HttpPost("{id}/profile-image")]
    public async Task<ActionResult<EmployeeDto>> UploadProfileImage(int id, [FromForm] IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = _localizer["NoFileUploaded"].Value });
        if (file.Length > MaxImageSizeBytes)
            return BadRequest(new { message = "Image size must be 5 MB or less." });

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedImageExtensions.Contains(extension))
            return BadRequest(new { message = "Unsupported image type." });

        var employee = await _context.Employees
            .Include(e => e.Users)
            .FirstOrDefaultAsync(e => e.id == id);
        if (employee == null)
            return this.EntityNotFound<EmployeeDto>(_localizer, "Employee");
        if (employee.Users == null)
            return BadRequest(new { message = "Employee does not have a linked user." });

        var storedPath = await SaveProfileImageAsync(file, "employees", extension);
        var previousPath = employee.Users.Profile_Image_Path;
        employee.Users.Profile_Image_Path = storedPath;
        await _context.SaveChangesAsync();
        DeletePhysicalFileIfExists(previousPath);

        var updated = await _employeeService.GetEmployeeAsync(id);
        if (updated == null)
            return this.EntityNotFound<EmployeeDto>(_localizer, "Employee");

        return Ok(updated);
    }

    // GET: api/employees/{id}/profile-image
    [HttpGet("{id}/profile-image")]
    public async Task<IActionResult> GetProfileImage(int id)
    {
        var employee = await _context.Employees
            .Include(e => e.Users)
            .FirstOrDefaultAsync(e => e.id == id);
        if (employee == null)
            return this.EntityNotFound(_localizer, "Employee");
        if (string.IsNullOrWhiteSpace(employee.Users?.Profile_Image_Path))
            return this.EntityNotFound(_localizer, "File");

        if (!TryResolveTrustedFilePath(employee.Users.Profile_Image_Path, out var fullPath))
            return this.EntityNotFound(_localizer, "File");
        if (!System.IO.File.Exists(fullPath))
            return this.EntityNotFound(_localizer, "File");

        var stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return File(stream, GetContentType(fullPath));
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var ok = await _employeeService.DeleteEmployeeAsync(id);
        if (!ok) return this.EntityNotFound(_localizer, "Employee");
        return Ok(new { message = _localizer["EmployeeDeleted"].Value });
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
