# Data Model: Competitor Feature Parity and Improvement

## 1. CompetitorCapability
- Purpose: Represents an externally observed user-facing capability from competitor systems.
- Key fields:
  - `CapabilityId` (unique identifier)
  - `Category` (case_management, client_communication, billing, compliance, reporting, operations)
  - `Title`
  - `Description`
  - `EvidenceSourceUrl`
  - `EvidenceCapturedAt`
  - `EvidenceConfidence` (low, medium, high)
  - `TenantScope` (tenant identifier)
  - `IsActive`
- Validation rules:
  - Category required and constrained to canonical set.
  - Evidence source required for active capabilities.
  - Tenant scope required for all mutable records.
- Relationships:
  - One `CompetitorCapability` to many `CoverageAssessment`.

## 2. CoverageAssessment
- Purpose: Records how current product coverage compares to a competitor capability.
- Key fields:
  - `AssessmentId` (unique identifier)
  - `CapabilityId` (FK -> CompetitorCapability)
  - `CoverageStatus` (covered, partially_covered, missing)
  - `BusinessImpactScore` (numeric bounded score)
  - `CustomerDemandScore` (numeric bounded score)
  - `StrategicRelevanceScore` (numeric bounded score)
  - `AssessmentNotes`
  - `AssessedByRole`
  - `AssessedByUserId`
  - `AssessedAt`
- Validation rules:
  - Status required.
  - Scores must be within agreed bounded range.
  - Editor must hold role permission.
- Relationships:
  - Many `CoverageAssessment` to one `CompetitorCapability`.
  - One `CoverageAssessment` can seed one `RoadmapItem`.

## 3. RoadmapItem
- Purpose: Represents a parity or differentiation initiative selected for delivery.
- Key fields:
  - `RoadmapItemId` (unique identifier)
  - `SourceAssessmentId` (FK -> CoverageAssessment, optional for improvement-only items)
  - `ItemType` (parity, improvement, differentiation)
  - `PriorityTier` (P1, P2, P3)
  - `ScopeLabel` (in_scope, deferred, out_of_scope)
  - `ProblemStatement`
  - `ExpectedUserOutcome`
  - `LifecycleState` (draft, approved, in_delivery, released, review_pending, completed)
  - `OwnerUserId`
  - `EditLockOwnerUserId` (nullable)
  - `EditLockAcquiredAt` (nullable)
  - `CreatedAt`
  - `UpdatedAt`
- Validation rules:
  - Problem statement and expected outcome required for approval.
  - Completion transition requires release proof + KPI success.
  - Lock owner required for active lock operations.
- Relationships:
  - One `RoadmapItem` to many `OutcomeMetric`.
  - One `RoadmapItem` to many `RoadmapChangeLog` entries.

## 4. OutcomeMetric
- Purpose: Tracks baseline and post-release values for roadmap validation.
- Key fields:
  - `MetricId` (unique identifier)
  - `RoadmapItemId` (FK -> RoadmapItem)
  - `MetricName`
  - `BaselineValue`
  - `TargetValue`
  - `ObservedValue`
  - `ReviewWindowDays`
  - `MeasuredAt`
  - `MeasurementStatus` (pending, met, unmet)
- Validation rules:
  - Baseline and target required before delivery starts.
  - Observed value required to finalize completion review.
- Relationships:
  - Many `OutcomeMetric` to one `RoadmapItem`.

## 5. RoadmapChangeLog
- Purpose: Audit trail for all roadmap edits and lifecycle transitions.
- Key fields:
  - `ChangeLogId` (unique identifier)
  - `RoadmapItemId` (FK -> RoadmapItem)
  - `ChangedByUserId`
  - `ChangedByRole`
  - `ChangeType` (create, update, lock, unlock, state_transition)
  - `ChangeSummary`
  - `ChangedAt`
- Validation rules:
  - Every update operation must produce one change log entry.
  - Role and user context required.
- Relationships:
  - Many `RoadmapChangeLog` to one `RoadmapItem`.

## State Transitions

### RoadmapItem LifecycleState
- `draft` -> `approved` (requires problem statement, expected outcome, role authorization)
- `approved` -> `in_delivery`
- `in_delivery` -> `released`
- `released` -> `review_pending` (awaiting metric review window completion)
- `review_pending` -> `completed` (only if metrics met)
- `review_pending` -> `in_delivery` (if metrics unmet and rework approved)

### Edit Lock Lifecycle
- `unlocked` -> `locked` (owner acquires lock)
- `locked` -> `unlocked` (owner releases, timeout, or admin override)
