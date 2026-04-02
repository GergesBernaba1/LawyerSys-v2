using System;

namespace LawyerSys.Data.ScaffoldedModels;

/// <summary>
/// Stores history of all generated documents
/// </summary>
public partial class GeneratedDocument
{
    public int Id { get; set; }
    
    public string TemplateType { get; set; } = string.Empty;
    
    public int? CaseCode { get; set; }
    
    public int? CustomerId { get; set; }
    
    public int? FileId { get; set; }
    
    public string Format { get; set; } = string.Empty;
    
    public string? DocumentTitle { get; set; }
    
    public string? DocumentReference { get; set; }
    
    public string? DocumentCategory { get; set; }
    
    public string? DocumentNotes { get; set; }

    public string? BrandingJson { get; set; }

    public string? PartiesJson { get; set; }

    public string? ClauseKeysJson { get; set; }
    
    public string? GeneratedContent { get; set; }
    
    public string GeneratedBy { get; set; } = string.Empty;
    
    public DateTime GeneratedAt { get; set; }
    
    public int Version { get; set; } = 1;
    
    public int? ParentDocumentId { get; set; }
    
    public bool IsDeleted { get; set; } = false;
    
    public int? TenantId { get; set; }
    
    // Navigation properties
    public virtual Case? Case { get; set; }
    
    public virtual Customer? Customer { get; set; }
    
    public virtual File? File { get; set; }
    
    public virtual GeneratedDocument? ParentDocument { get; set; }
    
    public virtual ICollection<GeneratedDocument> ChildDocuments { get; set; } = new List<GeneratedDocument>();
}
