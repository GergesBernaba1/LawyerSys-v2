using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Infrastructure.Repositories.Parity;

public sealed class ParityRepository
{
    private readonly ApplicationDbContext _dbContext;

    public ParityRepository(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<List<CompetitorCapability>> GetCapabilitiesForTenantAsync(int tenantId, CancellationToken cancellationToken)
    {
        return _dbContext.Set<CompetitorCapability>()
            .Where(x => x.TenantId == tenantId && x.IsActive)
            .AsNoTracking()
            .OrderBy(x => x.Category)
            .ThenBy(x => x.Title)
            .ToListAsync(cancellationToken);
    }
}
