using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LawyerSys.Data;
using FileEntity = LawyerSys.Data.ScaffoldedModels.File;
using LawyerSys.DTOs;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    private readonly LegacyDbContext _context;
    private readonly IWebHostEnvironment _env;

    public FilesController(LegacyDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    // GET: api/files
    [HttpGet]
    public async Task<ActionResult<IEnumerable<FileDto>>> GetFiles()
    {
        var files = await _context.Files.ToListAsync();
        return Ok(files.Select(MapToDto));
    }

    // GET: api/files/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<FileDto>> GetFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return NotFound(new { message = "File not found" });

        return Ok(MapToDto(file));
    }

    // POST: api/files
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost]
    public async Task<ActionResult<FileDto>> CreateFile([FromBody] CreateFileDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var file = new FileEntity
        {
            Path = dto.Path,
            Code = dto.Code,
            type = dto.Type
        };

        _context.Files.Add(file);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetFile), new { id = file.Id }, MapToDto(file));
    }

    // POST: api/files/upload
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPost("upload")]
    public async Task<ActionResult<FileDto>> UploadFile(IFormFile file, [FromForm] string? code)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "No file uploaded" });

        // Create uploads directory if not exists
        var uploadsPath = Path.Combine(_env.ContentRootPath, "Uploads");
        if (!Directory.Exists(uploadsPath))
            Directory.CreateDirectory(uploadsPath);

        // Generate unique filename
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(uploadsPath, fileName);

        // Save file
        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Determine file type (true = document, false = other)
        var extension = Path.GetExtension(file.FileName).ToLower();
        var isDocument = new[] { ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx" }.Contains(extension);

        var fileEntity = new FileEntity
        {
            Path = $"/Uploads/{fileName}",
            Code = code ?? Path.GetFileNameWithoutExtension(file.FileName),
            type = isDocument
        };

        _context.Files.Add(fileEntity);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetFile), new { id = fileEntity.Id }, MapToDto(fileEntity));
    }

    // PUT: api/files/{id}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateFile(int id, [FromBody] UpdateFileDto dto)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return NotFound(new { message = "File not found" });

        if (dto.Path != null) file.Path = dto.Path;
        if (dto.Code != null) file.Code = dto.Code;
        if (dto.Type.HasValue) file.type = dto.Type;

        await _context.SaveChangesAsync();

        return Ok(MapToDto(file));
    }

    // DELETE: api/files/{id}
    [Authorize(Policy = "EmployeeOrAdmin")]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null)
            return NotFound(new { message = "File not found" });

        // Delete physical file if exists
        if (!string.IsNullOrEmpty(file.Path))
        {
            var fullPath = Path.Combine(_env.ContentRootPath, file.Path.TrimStart('/'));
            if (System.IO.File.Exists(fullPath))
                System.IO.File.Delete(fullPath);
        }

        _context.Files.Remove(file);
        await _context.SaveChangesAsync();

        return Ok(new { message = "File deleted" });
    }

    // GET: api/files/{id}/download
    [HttpGet("{id}/download")]
    public async Task<IActionResult> DownloadFile(int id)
    {
        var file = await _context.Files.FindAsync(id);
        if (file == null || string.IsNullOrEmpty(file.Path))
            return NotFound(new { message = "File not found" });

        var fullPath = Path.Combine(_env.ContentRootPath, file.Path.TrimStart('/'));
        if (!System.IO.File.Exists(fullPath))
            return NotFound(new { message = "Physical file not found" });

        var contentType = GetContentType(fullPath);
        var fileName = Path.GetFileName(fullPath);

        return PhysicalFile(fullPath, contentType, fileName);
    }

    private static FileDto MapToDto(FileEntity f) => new()
    {
        Id = f.Id,
        Path = f.Path,
        Code = f.Code,
        Type = f.type
    };

    private static string GetContentType(string path)
    {
        var ext = Path.GetExtension(path).ToLower();
        return ext switch
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
    }
}
