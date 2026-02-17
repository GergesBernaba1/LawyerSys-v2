using System.ComponentModel.DataAnnotations;

namespace LawyerSys.DTOs;

public class FileDto
{
    public int Id { get; set; }
    public string? Path { get; set; }
    public string? Code { get; set; }
    public bool? Type { get; set; }
}

public class CreateFileDto
{
    [Required]
    [MaxLength(1000)]
    public string? Path { get; set; }

    [Required]
    [MaxLength(200)]
    public string? Code { get; set; }
    public bool? Type { get; set; }
}

public class UpdateFileDto
{
    [MaxLength(1000)]
    public string? Path { get; set; }

    [MaxLength(200)]
    public string? Code { get; set; }
    public bool? Type { get; set; }
}
