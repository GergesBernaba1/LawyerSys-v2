using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using LawyerSys.Data;
using LawyerSys.Extensions;
using LawyerSys.Resources;
using LawyerSys.Services;
using LawyerSys.DTOs;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private static readonly string[] AllowedUploadExtensions = new[] { ".pdf", ".doc", ".docx", ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" };
    private static readonly string[] DocumentExtensions = new[] { ".pdf", ".doc", ".docx" };

    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;
    private readonly IUserContext _userContext;
    private readonly IEmployeeAccessService _employeeAccessService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public FilesController(
        LegacyDbContext context,
        IWebHostEnvironment env,
        IUserContext userContext,
        IEmployeeAccessService employeeAccessService,
        IStringLocalizer<SharedResource> localizer)
    {
        _context = context;
        _env = env;
        _userContext = userContext;
        _employeeAccessService = employeeAccessService;
        _localizer = localizer;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<FileDto>>> GetFiles([FromQuery] int? page = null, [FromQuery] int? pageSize = null, [FromQuery] string? search = null)
    {
        IQueryable<FileEntity> query = _context.Files;
        var customerId = await GetCurrentCustomerIdAsync();

        if (customerId.HasValue)
        {
            var caseIds = _context.Custmors_Cases.Where(cc => cc.Custmors_Id == customerId.Value).Select(cc => cc.Case_Id);
            var fileIds = _context.Cases_Files.Where(cf => caseIds.Contains(cf.Case_Id)).Select(cf => cf.File_Id);
            query = query.Where(f => fileIds.Contains(f.Id));
        }
        else if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var assignedCaseCodes = await _employeeAccessService.GetAssignedCaseCodesAsync();
            var fileIds = _context.Cases_Files.Where(cf => assignedCaseCodes.Contains(cf.Case_Id)).Select(cf => cf.File_Id);
            query = assignedCaseCodes.Length == 0 ? query.Where(_ => false) : query.Where(f => fileIds.Contains(f.Id));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(f => (f.Path != null && f.Path.Contains(s)) || (f.Code != null && f.Code.Contains(s)));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync();
            var items = await query.OrderBy(f => f.Id).Skip((p - 1) * ps).Take(ps).ToListAsync();
            return Ok(new PagedResult<FileDto> { Items = items.Select(MapToDto), TotalCount = total, Page = p, PageSize = ps });
        }

        var files = await query.OrderBy(f => f.Id).ToListAsync();
        return Ok(files.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<FileDto>> GetFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return this.EntityNotFound<FileDto>(_localizer, "File");
        if (!await CanAccessFileAsync(id))
            return Forbid();
        return Ok(MapToDto(file));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<FileDto>> CreateFile([FromBody] CreateFileDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var file = new FileEntity { Path = dto.Path, Code = dto.Code, type = dto.Type };
        _context.Files.Add(file);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetFile), new { id = file.Id }, MapToDto(file));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("upload")]
    public async Task<ActionResult<FileDto>> UploadFile(IFormFile file, [FromForm] string? title, [FromForm] string? description, [FromForm] string? code)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = _localizer["NoFileUploaded"].Value });

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedUploadExtensions.Contains(extension))
            return BadRequest(new { message = _localizer["UnsupportedFileType"].Value });

        var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
        if (!Directory.Exists(uploadsPath))
            Directory.CreateDirectory(uploadsPath);

        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
            await file.CopyToAsync(stream);

        var isDocument = DocumentExtensions.Contains(extension);
        var titleOrDescription = !string.IsNullOrWhiteSpace(title) ? title.Trim()
            : !string.IsNullOrWhiteSpace(description) ? description.Trim() : code;

        var fileEntity = new FileEntity
        {
            Path = $"/Uploads/{fileName}",
            Code = string.IsNullOrWhiteSpace(titleOrDescription) ? Path.GetFileNameWithoutExtension(file.FileName) : titleOrDescription,
            type = isDocument
        };

        _context.Files.Add(fileEntity);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetFile), new { id = fileEntity.Id }, MapToDto(fileEntity));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateFile(int id, [FromBody] UpdateFileDto dto)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return this.EntityNotFound(_localizer, "File");
        if (!await CanAccessFileAsync(id))
            return Forbid();

        if (dto.Path != null) file.Path = dto.Path;
        if (dto.Code != null) file.Code = dto.Code;
        if (dto.Type.HasValue) file.type = dto.Type;

        await _context.SaveChangesAsync();
        return Ok(MapToDto(file));
    }

    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return this.EntityNotFound(_localizer, "File");
        if (!await CanAccessFileAsync(id))
            return Forbid();

        if (!string.IsNullOrEmpty(file.Path))
        {
            if (!TryResolveTrustedFilePath(file.Path, out var fullPath))
                return BadRequest(new { message = _localizer["PhysicalFileNotFound"].Value });
            if (System.IO.File.Exists(fullPath))
                System.IO.File.Delete(fullPath);
        }

        _context.Files.Remove(file);
        await _context.SaveChangesAsync();
        return Ok(new { message = _localizer["FileDeleted"].Value });
    }

    [HttpGet("{id}/download")]
    public async Task<IActionResult> DownloadFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null || string.IsNullOrEmpty(file.Path))
            return this.EntityNotFound(_localizer, "File");
        if (!await CanAccessFileAsync(id))
            return Forbid();

        if (!TryResolveTrustedFilePath(file.Path, out var fullPath))
            return NotFound(new { message = _localizer["PhysicalFileNotFound"].Value });
        if (!System.IO.File.Exists(fullPath))
            return NotFound(new { message = _localizer["PhysicalFileNotFound"].Value });

        return PhysicalFile(fullPath, GetContentType(fullPath), Path.GetFileName(fullPath));
    }

    [HttpGet("{id}/view")]
    public async Task<IActionResult> ViewFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null || string.IsNullOrEmpty(file.Path))
            return this.EntityNotFound(_localizer, "File");
        if (!await CanAccessFileAsync(id))
            return Forbid();

        if (!TryResolveTrustedFilePath(file.Path, out var fullPath))
            return NotFound(new { message = _localizer["PhysicalFileNotFound"].Value });
        if (!System.IO.File.Exists(fullPath))
            return NotFound(new { message = _localizer["PhysicalFileNotFound"].Value });

        var stream = new FileStream(fullPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return File(stream, GetContentType(fullPath));
    }

    private static FileDto MapToDto(FileEntity f) => new() { Id = f.Id, Path = f.Path, Code = f.Code, Type = f.type };

    private static string GetContentType(string path) => Path.GetExtension(path).ToLower() switch
    {
        ".pdf" => "application/pdf",
        ".doc" => "application/msword",
        ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ".xls" => "application/vnd.ms-excel",
        ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ".txt" => "text/plain",
        ".png" => "image/png",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".gif" => "image/gif",
        _ => "application/octet-stream"
    };

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

    private async Task<int?> GetCurrentCustomerIdAsync()
    {
        var roles = await _userContext.GetUserRolesAsync();
        var isCustomerOnly = roles.Contains("Customer") && !roles.Contains("SuperAdmin") && !roles.Contains("Admin") && !roles.Contains("Employee");
        if (!isCustomerOnly) return null;

        var userName = _userContext.GetUserName();
        if (string.IsNullOrWhiteSpace(userName)) return -1;

        return await _context.Customers
            .Include(c => c.Users)
            .Where(c => c.Users != null && c.Users.User_Name == userName)
            .Select(c => (int?)c.Id)
            .FirstOrDefaultAsync() ?? -1;
    }

    private async Task<bool> CanAccessFileAsync(int fileId)
    {
        var customerId = await GetCurrentCustomerIdAsync();
        if (customerId.HasValue)
        {
            if (customerId.Value <= 0) return false;
            return await _context.Cases_Files.AnyAsync(cf =>
                cf.File_Id == fileId &&
                _context.Custmors_Cases.Any(cc => cc.Case_Id == cf.Case_Id && cc.Custmors_Id == customerId.Value));
        }

        if (await _employeeAccessService.IsCurrentUserEmployeeOnlyAsync())
        {
            var assignedCaseCodes = await _employeeAccessService.GetAssignedCaseCodesAsync();
            if (assignedCaseCodes.Length == 0) return false;
            return await _context.Cases_Files.AnyAsync(cf => cf.File_Id == fileId && assignedCaseCodes.Contains(cf.Case_Id));
        }

        return true;
    }
}
