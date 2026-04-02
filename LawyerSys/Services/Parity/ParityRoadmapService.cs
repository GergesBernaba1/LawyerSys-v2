using LawyerSys.Infrastructure.Repositories.Parity;

namespace LawyerSys.Services.Parity;

public sealed partial class ParityRoadmapService : IParityRoadmapService
{
    private readonly ParityRepository _repository;

    public ParityRoadmapService(ParityRepository repository)
    {
        _repository = repository;
    }
}
