namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public Task<IReadOnlyList<RoadmapItemDto>> GetRoadmapItemsAsync(CancellationToken cancellationToken)
    {
        IReadOnlyList<RoadmapItemDto> result = Array.Empty<RoadmapItemDto>();
        return Task.FromResult(result);
    }
}
