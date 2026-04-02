using System;

namespace LawyerSys.Data.ScaffoldedModels;

/// <summary>
/// Stores incomplete/work-in-progress documents
/// </summary>
public partial class DocumentDraft
{
    public int Id { get; set; }
    
    public string TemplateType { get; set; } = string.Empty;
    
    public int? CaseCode { get; set; }
    
    public int? CustomerId { get; set; }
    
    public string Format { get; set; } = "docx";
    
    public string? Scope { get; set; }
    
    public string? FeeTerms { get; set; }
    
    public string? Subject { get; set; }
    
    public string? Statement { get; set; }
    
    public string? AiInstructions { get; set; }
    
    public string? PreviewContent { get; set; }
    
    public string? DocumentTitle { get; set; }
    
    public string? DocumentReference { get; set; }
    
    public string? DocumentCategory { get; set; }
    
    public string? DocumentNotes { get; set; }

    public string? BrandingJson { get; set; }

    public string? PartiesJson { get; set; }

    public string? ClauseKeysJson { get; set; }
    
    public bool SaveToCase { get; set; } = false;
    
    public string CreatedBy { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; }
    
    public DateTime LastModifiedAt { get; set; }
    
    public string? DraftName { get; set; }
    
    public bool IsDeleted { get; set; } = false;
    
    public int? TenantId { get; set; }
    
    // Navigation properties
    public virtual Case? Case { get; set; }
    
    public virtual Customer? Customer { get; set; }
}
