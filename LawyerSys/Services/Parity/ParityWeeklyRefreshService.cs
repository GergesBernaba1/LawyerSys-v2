namespace LawyerSys.Services.Parity;

public sealed class ParityWeeklyRefreshService
{
    public Task RunAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
