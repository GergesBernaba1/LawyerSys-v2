namespace LawyerSys.Services.Parity;

public sealed record ParityCapabilityDto(
    string CapabilityId,
    string Category,
    string Title,
    string? Description,
    string EvidenceSourceUrl,
    DateTimeOffset EvidenceCapturedAt,
    string EvidenceConfidence,
    int TenantId);

public sealed record CoverageAssessmentDto(
    string AssessmentId,
    string CapabilityId,
    string CoverageStatus,
    decimal BusinessImpactScore,
    decimal CustomerDemandScore,
    decimal StrategicRelevanceScore,
    string? AssessmentNotes,
    string AssessedByRole,
    string AssessedByUserId,
    DateTimeOffset AssessedAt);

public sealed record RoadmapItemDto(
    string RoadmapItemId,
    string ItemType,
    string PriorityTier,
    string ScopeLabel,
    string LifecycleState,
    string ProblemStatement,
    string ExpectedUserOutcome,
    string? OwnerUserId);

public sealed record OutcomeMetricDto(
    string MetricId,
    string RoadmapItemId,
    string MetricName,
    decimal BaselineValue,
    decimal TargetValue,
    decimal? ObservedValue,
    int ReviewWindowDays,
    string MeasurementStatus,
    DateTimeOffset? MeasuredAt);
