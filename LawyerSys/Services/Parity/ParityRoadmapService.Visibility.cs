namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public Task<IReadOnlyList<RoadmapItemDto>> GetRoadmapItemsForRoleAsync(string role, CancellationToken cancellationToken)
    {
        return GetRoadmapItemsAsync(cancellationToken);
    }
}
