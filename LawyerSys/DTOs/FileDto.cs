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
    public string? Path { get; set; }
    public string? Code { get; set; }
    public bool? Type { get; set; }
}

public class UpdateFileDto
{
    public string? Path { get; set; }
    public string? Code { get; set; }
    public bool? Type { get; set; }
}
