using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Contenders;

public sealed class ContendersService : IContendersService
{
    private readonly LegacyDbContext _context;

    public ContendersService(LegacyDbContext context)
    {
        _context = context;
    }

    public async Task<QueryResult<ContenderDto>> GetContendersAsync(int? page, int? pageSize, string? search, CancellationToken cancellationToken = default)
    {
        IQueryable<Contender> query = _context.Contenders;

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim();
            query = query.Where(c => c.Full_Name.Contains(s) || c.SSN.ToString().Contains(s));
        }

        if (page.HasValue && pageSize.HasValue)
        {
            var p = Math.Max(1, page.Value);
            var ps = Math.Clamp(pageSize.Value, 1, 200);
            var total = await query.CountAsync(cancellationToken);
            var items = await query.OrderBy(c => c.Id).Skip((p - 1) * ps).Take(ps).ToListAsync(cancellationToken);
            return new QueryResult<ContenderDto>
            {
                Items = items.Select(MapToDto).ToList(),
                TotalCount = total,
                Page = p,
                PageSize = ps
            };
        }

        var contenders = await query.OrderBy(c => c.Id).ToListAsync(cancellationToken);
        return new QueryResult<ContenderDto> { Items = contenders.Select(MapToDto).ToList() };
    }

    public async Task<ContenderDto?> GetContenderAsync(int id, CancellationToken cancellationToken = default)
    {
        var contender = await _context.Contenders.FindAsync([id], cancellationToken);
        return contender == null ? null : MapToDto(contender);
    }

    public async Task<ContenderDto> CreateContenderAsync(CreateContenderDto dto, CancellationToken cancellationToken = default)
    {
        var contender = new Contender
        {
            Full_Name = dto.FullName,
            SSN = int.TryParse(dto.SSN, out var ssn) ? ssn : 0,
            BirthDate = dto.BirthDate,
            Type = dto.Type
        };

        _context.Contenders.Add(contender);
        await _context.SaveChangesAsync(cancellationToken);
        return MapToDto(contender);
    }

    public async Task<ContenderDto?> UpdateContenderAsync(int id, UpdateContenderDto dto, CancellationToken cancellationToken = default)
    {
        var contender = await _context.Contenders.FindAsync([id], cancellationToken);
        if (contender == null)
        {
            return null;
        }

        if (dto.FullName != null)
        {
            contender.Full_Name = dto.FullName;
        }
        if (dto.SSN != null && int.TryParse(dto.SSN, out var ssn))
        {
            contender.SSN = ssn;
        }
        if (dto.BirthDate.HasValue)
        {
            contender.BirthDate = dto.BirthDate.Value;
        }
        if (dto.Type.HasValue)
        {
            contender.Type = dto.Type;
        }

        await _context.SaveChangesAsync(cancellationToken);
        return MapToDto(contender);
    }

    public async Task<bool> DeleteContenderAsync(int id, CancellationToken cancellationToken = default)
    {
        var contender = await _context.Contenders.FindAsync([id], cancellationToken);
        if (contender == null)
        {
            return false;
        }

        _context.Contenders.Remove(contender);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static ContenderDto MapToDto(Contender c) => new()
    {
        Id = c.Id,
        FullName = c.Full_Name,
        SSN = c.SSN.ToString(),
        BirthDate = c.BirthDate,
        Type = c.Type
    };
}
