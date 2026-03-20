using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using LawyerSys.Data;
using LawyerSys.Data.ScaffoldedModels;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services
{
    public class CourtService : ICourtService
    {
        private readonly LegacyDbContext _context;
        private readonly ApplicationDbContext _applicationDbContext;
        private readonly IUserContext _userContext;

        public CourtService(
            LegacyDbContext context,
            ApplicationDbContext applicationDbContext,
            IUserContext userContext)
        {
            _context = context;
            _applicationDbContext = applicationDbContext;
            _userContext = userContext;
        }

        public async Task<IEnumerable<CourtDto>> GetCourtsAsync(string? search = null)
        {
            var courts = await GetCourtsQuery(search).OrderBy(c => c.Id).ToListAsync();
            return courts.Select(MapToDto);
        }

        public async Task<PagedResult<CourtDto>> GetCourtsAsync(int page, int pageSize, string? search)
        {
            var query = GetCourtsQuery(search);
            var total = await query.CountAsync();
            var items = await query.OrderBy(c => c.Id).Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            return new PagedResult<CourtDto>
            {
                Items = items.Select(MapToDto),
                TotalCount = total,
                Page = page,
                PageSize = pageSize
            };
        }

        private IQueryable<Court> GetCourtsQuery(string? search)
        {
            IQueryable<Court> query = _context.Courts.Include(c => c.Gov);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim();
                query = query.Where(c =>
                    c.Name.Contains(s) ||
                    c.Address.Contains(s) ||
                    c.Telephone.Contains(s) ||
                    c.Notes.Contains(s) ||
                    (c.Gov != null && c.Gov.Gov_Name.Contains(s)));
            }

            return query;
        }

        public async Task<CourtDto?> GetCourtAsync(int id)
        {
            var court = await _context.Courts
                .Include(c => c.Gov)
                .FirstOrDefaultAsync(c => c.Id == id);

            return court == null ? null : MapToDto(court);
        }

        public async Task<CourtDto> CreateCourtAsync(CreateCourtDto dto)
        {
            if (!await CanUseGovernmentAsync(dto.GovId))
                throw new InvalidOperationException("SelectedCityOutsideProfileCountry");

            var court = new Court
            {
                Name = dto.Name,
                Address = dto.Address,
                Telephone = dto.Telephone,
                Notes = dto.Notes ?? string.Empty,
                Gov_Id = dto.GovId
            };

            _context.Courts.Add(court);
            await _context.SaveChangesAsync();

            await _context.Entry(court).Reference(c => c.Gov).LoadAsync();
            return MapToDto(court);
        }

        public async Task<CourtDto> UpdateCourtAsync(int id, UpdateCourtDto dto)
        {
            var court = await _context.Courts.Include(c => c.Gov).FirstOrDefaultAsync(c => c.Id == id);
            if (court == null)
                throw new ArgumentException("Court not found");

            if (dto.GovId.HasValue && !await CanUseGovernmentAsync(dto.GovId.Value))
                throw new InvalidOperationException("SelectedCityOutsideProfileCountry");

            if (dto.Name != null) court.Name = dto.Name;
            if (dto.Address != null) court.Address = dto.Address;
            if (dto.Telephone != null) court.Telephone = dto.Telephone;
            if (dto.Notes != null) court.Notes = dto.Notes;
            if (dto.GovId.HasValue) court.Gov_Id = dto.GovId.Value;

            await _context.SaveChangesAsync();
            return MapToDto(court);
        }

        public async Task<bool> DeleteCourtAsync(int id)
        {
            var court = await _context.Courts.FindAsync(id);
            if (court == null)
                return false;

            _context.Courts.Remove(court);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<IEnumerable<GovernamentDto>> GetGovernmentOptionsAsync()
        {
            var items = await GetAllowedGovernmentOptionsAsync();
            return items;
        }

        public async Task<bool> CanUseGovernmentAsync(int governmentId)
        {
            var allowedGovernmentIds = await GetAllowedGovernmentIdsAsync();
            return allowedGovernmentIds.Contains(governmentId);
        }

        private async Task<List<int>> GetAllowedGovernmentIdsAsync()
        {
            var options = await GetAllowedGovernmentOptionsAsync();
            return options.Select(option => option.Id).ToList();
        }

        private async Task<List<GovernamentDto>> GetAllowedGovernmentOptionsAsync()
        {
            var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
            var currentUserId = _userContext.GetUserId();
            if (string.IsNullOrWhiteSpace(currentUserId))
            {
                return new List<GovernamentDto>();
            }

            var countryId = await _applicationDbContext.Users
                .AsNoTracking()
                .Where(user => user.Id == currentUserId)
                .Select(user => user.CountryId)
                .SingleOrDefaultAsync();

            if (countryId is null or <= 0)
            {
                return new List<GovernamentDto>();
            }

            var cities = await _applicationDbContext.Cities
                .AsNoTracking()
                .Where(city => city.CountryId == countryId.Value)
                .OrderBy(city => city.Name)
                .Select(city => new { city.Name, city.NameAr })
                .ToListAsync();

            if (cities.Count == 0)
            {
                return new List<GovernamentDto>();
            }

            var governments = await _context.Governaments.ToListAsync();
            var byName = governments
                .GroupBy(government => NormalizeGovernmentName(government.Gov_Name))
                .ToDictionary(group => group.Key, group => group.First());

            var nextId = governments.Count == 0 ? 1 : governments.Max(government => government.Id) + 1;
            var items = new List<GovernamentDto>();

            foreach (var city in cities)
            {
                var normalizedEnglish = NormalizeGovernmentName(city.Name);
                var normalizedArabic = NormalizeGovernmentName(city.NameAr);

                Governament? government = null;
                if (!byName.TryGetValue(normalizedEnglish, out government) &&
                    !string.IsNullOrWhiteSpace(normalizedArabic) &&
                    !byName.TryGetValue(normalizedArabic, out government))
                {
                    government = new Governament
                    {
                        Id = nextId++,
                        Gov_Name = city.Name
                    };

                    _context.Governaments.Add(government);
                    byName[normalizedEnglish] = government;

                    if (!string.IsNullOrWhiteSpace(normalizedArabic))
                    {
                        byName[normalizedArabic] = government;
                    }
                }

                if (government != null)
                {
                    items.Add(new GovernamentDto
                    {
                        Id = government.Id,
                        GovName = useArabic && !string.IsNullOrWhiteSpace(city.NameAr)
                            ? city.NameAr
                            : city.Name
                    });
                }
            }

            if (_context.ChangeTracker.HasChanges())
            {
                await _context.SaveChangesAsync();
            }

            return items;
        }

        private static string NormalizeGovernmentName(string? value)
        {
            return (value ?? string.Empty).Trim().ToLower();
        }

        private static CourtDto MapToDto(Court c) => new()
        {
            Id = c.Id,
            Name = c.Name,
            Address = c.Address,
            Telephone = c.Telephone,
            Notes = c.Notes,
            GovId = c.Gov_Id,
            GovernmentName = c.Gov?.Gov_Name
        };
    }
}
