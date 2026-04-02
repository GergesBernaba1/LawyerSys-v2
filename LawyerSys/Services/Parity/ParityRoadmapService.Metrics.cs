namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService
{
    public Task RecordMetricAsync(string roadmapItemId, CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
