namespace LawyerSys.Services.Parity;

public interface IParityRoadmapService
{
    Task<IReadOnlyList<ParityCapabilityDto>> GetCapabilitiesAsync(CancellationToken cancellationToken);
    Task<IReadOnlyList<RoadmapItemDto>> GetRoadmapItemsAsync(CancellationToken cancellationToken);
}
