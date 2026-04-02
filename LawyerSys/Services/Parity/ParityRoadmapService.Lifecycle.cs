namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public Task<bool> TryTransitionStateAsync(string roadmapItemId, string targetState, CancellationToken cancellationToken)
    {
        var allowed = !string.Equals(targetState, "completed", StringComparison.OrdinalIgnoreCase);
        return Task.FromResult(allowed);
    }
}
