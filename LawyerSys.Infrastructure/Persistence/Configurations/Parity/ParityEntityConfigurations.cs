using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LawyerSys.Infrastructure.Persistence.Configurations.Parity;

public sealed class CompetitorCapabilityConfiguration : IEntityTypeConfiguration<CompetitorCapability>
{
    public void Configure(EntityTypeBuilder<CompetitorCapability> builder)
    {
        builder.ToTable("ParityCompetitorCapabilities");
        builder.HasKey(x => x.CapabilityId);
        builder.Property(x => x.Category).HasMaxLength(64);
        builder.Property(x => x.Title).HasMaxLength(200);
        builder.Property(x => x.EvidenceSourceUrl).HasMaxLength(500);
        builder.HasIndex(x => new { x.TenantId, x.Category });
    }
}

public sealed class CoverageAssessmentConfiguration : IEntityTypeConfiguration<CoverageAssessment>
{
    public void Configure(EntityTypeBuilder<CoverageAssessment> builder)
    {
        builder.ToTable("ParityCoverageAssessments");
        builder.HasKey(x => x.AssessmentId);
        builder.Property(x => x.CoverageStatus).HasMaxLength(32);
        builder.HasOne(x => x.Capability)
            .WithMany(x => x.Assessments)
            .HasForeignKey(x => x.CapabilityId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class RoadmapItemConfiguration : IEntityTypeConfiguration<RoadmapItem>
{
    public void Configure(EntityTypeBuilder<RoadmapItem> builder)
    {
        builder.ToTable("ParityRoadmapItems");
        builder.HasKey(x => x.RoadmapItemId);
        builder.Property(x => x.ItemType).HasMaxLength(32);
        builder.Property(x => x.PriorityTier).HasMaxLength(8);
        builder.Property(x => x.ScopeLabel).HasMaxLength(32);
        builder.Property(x => x.LifecycleState).HasMaxLength(32);
        builder.HasIndex(x => new { x.TenantId, x.PriorityTier, x.LifecycleState });
    }
}

public sealed class OutcomeMetricConfiguration : IEntityTypeConfiguration<OutcomeMetric>
{
    public void Configure(EntityTypeBuilder<OutcomeMetric> builder)
    {
        builder.ToTable("ParityOutcomeMetrics");
        builder.HasKey(x => x.MetricId);
        builder.Property(x => x.MetricName).HasMaxLength(150);
        builder.Property(x => x.MeasurementStatus).HasMaxLength(32);
        builder.HasOne(x => x.RoadmapItem)
            .WithMany(x => x.OutcomeMetrics)
            .HasForeignKey(x => x.RoadmapItemId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class RoadmapChangeLogConfiguration : IEntityTypeConfiguration<RoadmapChangeLog>
{
    public void Configure(EntityTypeBuilder<RoadmapChangeLog> builder)
    {
        builder.ToTable("ParityRoadmapChangeLogs");
        builder.HasKey(x => x.ChangeLogId);
        builder.Property(x => x.ChangedByRole).HasMaxLength(64);
        builder.Property(x => x.ChangeType).HasMaxLength(64);
        builder.Property(x => x.ChangeSummary).HasMaxLength(1000);
        builder.HasOne(x => x.RoadmapItem)
            .WithMany(x => x.ChangeLogs)
            .HasForeignKey(x => x.RoadmapItemId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
