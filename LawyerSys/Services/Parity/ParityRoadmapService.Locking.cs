namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public Task<bool> TryAcquireLockAsync(string roadmapItemId, string userId, CancellationToken cancellationToken)
    {
        return Task.FromResult(true);
    }
}
