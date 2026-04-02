namespace LawyerSys.Services.Parity;

public sealed class ParityChangeLogWriter
{
    public RoadmapChangeLog CreateLog(Guid roadmapItemId, string userId, string role, string changeType, string summary)
    {
        return new RoadmapChangeLog
        {
            RoadmapItemId = roadmapItemId,
            ChangedByUserId = userId,
            ChangedByRole = role,
            ChangeType = changeType,
            ChangeSummary = summary,
            ChangedAt = DateTimeOffset.UtcNow
        };
    }
}
