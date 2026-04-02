namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public async Task<IReadOnlyList<ParityCapabilityDto>> GetCapabilitiesAsync(CancellationToken cancellationToken)
    {
        // Placeholder tenant until tenant-aware operation context is connected.
        var records = await _repository.GetCapabilitiesForTenantAsync(1, cancellationToken);
        return records
            .Select(x => new ParityCapabilityDto(
                x.CapabilityId.ToString(),
                x.Category,
                x.Title,
                x.Description,
                x.EvidenceSourceUrl,
                x.EvidenceCapturedAt,
                x.EvidenceConfidence,
                x.TenantId))
            .ToList();
    }
}
