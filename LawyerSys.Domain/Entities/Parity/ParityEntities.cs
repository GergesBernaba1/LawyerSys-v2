using System;
using System.Collections.Generic;

public class CompetitorCapability
{
    public Guid CapabilityId { get; set; } = Guid.NewGuid();
    public int TenantId { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string EvidenceSourceUrl { get; set; } = string.Empty;
    public DateTimeOffset EvidenceCapturedAt { get; set; } = DateTimeOffset.UtcNow;
    public string EvidenceConfidence { get; set; } = "medium";
    public bool IsActive { get; set; } = true;

    public ICollection<CoverageAssessment> Assessments { get; set; } = new List<CoverageAssessment>();
}

public class CoverageAssessment
{
    public Guid AssessmentId { get; set; } = Guid.NewGuid();
    public Guid CapabilityId { get; set; }
    public string CoverageStatus { get; set; } = "missing";
    public decimal BusinessImpactScore { get; set; }
    public decimal CustomerDemandScore { get; set; }
    public decimal StrategicRelevanceScore { get; set; }
    public string? AssessmentNotes { get; set; }
    public string AssessedByRole { get; set; } = string.Empty;
    public string AssessedByUserId { get; set; } = string.Empty;
    public DateTimeOffset AssessedAt { get; set; } = DateTimeOffset.UtcNow;

    public CompetitorCapability? Capability { get; set; }
}

public class RoadmapItem
{
    public Guid RoadmapItemId { get; set; } = Guid.NewGuid();
    public Guid? SourceAssessmentId { get; set; }
    public int TenantId { get; set; }
    public string ItemType { get; set; } = "parity";
    public string PriorityTier { get; set; } = "P3";
    public string ScopeLabel { get; set; } = "in_scope";
    public string LifecycleState { get; set; } = "draft";
    public string ProblemStatement { get; set; } = string.Empty;
    public string ExpectedUserOutcome { get; set; } = string.Empty;
    public string? OwnerUserId { get; set; }
    public string? EditLockOwnerUserId { get; set; }
    public DateTimeOffset? EditLockAcquiredAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<OutcomeMetric> OutcomeMetrics { get; set; } = new List<OutcomeMetric>();
    public ICollection<RoadmapChangeLog> ChangeLogs { get; set; } = new List<RoadmapChangeLog>();
}

public class OutcomeMetric
{
    public Guid MetricId { get; set; } = Guid.NewGuid();
    public Guid RoadmapItemId { get; set; }
    public string MetricName { get; set; } = string.Empty;
    public decimal BaselineValue { get; set; }
    public decimal TargetValue { get; set; }
    public decimal? ObservedValue { get; set; }
    public int ReviewWindowDays { get; set; } = 30;
    public string MeasurementStatus { get; set; } = "pending";
    public DateTimeOffset? MeasuredAt { get; set; }

    public RoadmapItem? RoadmapItem { get; set; }
}

public class RoadmapChangeLog
{
    public Guid ChangeLogId { get; set; } = Guid.NewGuid();
    public Guid RoadmapItemId { get; set; }
    public string ChangedByUserId { get; set; } = string.Empty;
    public string ChangedByRole { get; set; } = string.Empty;
    public string ChangeType { get; set; } = string.Empty;
    public string ChangeSummary { get; set; } = string.Empty;
    public DateTimeOffset ChangedAt { get; set; } = DateTimeOffset.UtcNow;

    public RoadmapItem? RoadmapItem { get; set; }
}
