using System.Globalization;
using LawyerSys.Data;
using LawyerSys.DTOs;
using Microsoft.EntityFrameworkCore;

namespace LawyerSys.Services.Subscriptions;

public sealed class SubscriptionPackagesService : ISubscriptionPackagesService
{
    private readonly ApplicationDbContext _applicationDbContext;

    public SubscriptionPackagesService(ApplicationDbContext applicationDbContext)
    {
        _applicationDbContext = applicationDbContext;
    }

    public async Task<IReadOnlyList<SubscriptionPackagePublicGroupDto>> GetPublicPackagesAsync(CancellationToken cancellationToken = default)
    {
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var rows = await _applicationDbContext.SubscriptionPackages
            .AsNoTracking()
            .Where(package => package.IsActive)
            .OrderBy(package => package.DisplayOrder)
            .ThenBy(package => package.BillingCycle)
            .ToListAsync(cancellationToken);

        return BuildPublicPackageGroups(rows, useArabic);
    }

    public async Task<IReadOnlyList<SubscriptionPackageAdminGroupDto>> GetPackagesAsync(CancellationToken cancellationToken = default)
    {
        var rows = await _applicationDbContext.SubscriptionPackages
            .AsNoTracking()
            .OrderBy(package => package.DisplayOrder)
            .ThenBy(package => package.BillingCycle)
            .ToListAsync(cancellationToken);

        return BuildAdminPackageGroups(rows);
    }

    public async Task<bool> UpsertPackageGroupAsync(string officeSize, SaveSubscriptionPackageGroupRequest request, CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<SubscriptionOfficeSize>(officeSize, true, out var parsedOfficeSize))
        {
            return false;
        }

        var now = DateTime.UtcNow;
        var rows = await _applicationDbContext.SubscriptionPackages
            .Where(package => package.OfficeSize == parsedOfficeSize)
            .ToListAsync(cancellationToken);

        var monthly = rows.SingleOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Monthly)
            ?? new SubscriptionPackage
            {
                OfficeSize = parsedOfficeSize,
                BillingCycle = SubscriptionBillingCycle.Monthly,
                CreatedAtUtc = now,
            };

        var annual = rows.SingleOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Annual)
            ?? new SubscriptionPackage
            {
                OfficeSize = parsedOfficeSize,
                BillingCycle = SubscriptionBillingCycle.Annual,
                CreatedAtUtc = now,
            };

        ApplySharedFields(monthly, request, now);
        ApplySharedFields(annual, request, now);
        monthly.Price = request.MonthlyPrice;
        annual.Price = request.AnnualPrice;

        if (monthly.Id == 0)
        {
            _applicationDbContext.SubscriptionPackages.Add(monthly);
        }

        if (annual.Id == 0)
        {
            _applicationDbContext.SubscriptionPackages.Add(annual);
        }

        await _applicationDbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static void ApplySharedFields(SubscriptionPackage package, SaveSubscriptionPackageGroupRequest request, DateTime now)
    {
        package.Name = Normalize(request.Name);
        package.NameAr = Normalize(request.NameAr);
        package.Description = Normalize(request.Description);
        package.DescriptionAr = Normalize(request.DescriptionAr);
        package.Feature1 = Normalize(request.Feature1);
        package.Feature1Ar = Normalize(request.Feature1Ar);
        package.Feature2 = Normalize(request.Feature2);
        package.Feature2Ar = Normalize(request.Feature2Ar);
        package.Feature3 = Normalize(request.Feature3);
        package.Feature3Ar = Normalize(request.Feature3Ar);
        package.Currency = Normalize(request.Currency, "SAR");
        package.IsActive = request.IsActive;
        package.DisplayOrder = request.DisplayOrder;
        package.UpdatedAtUtc = now;
    }

    private static IReadOnlyList<SubscriptionPackagePublicGroupDto> BuildPublicPackageGroups(
        IEnumerable<SubscriptionPackage> rows,
        bool useArabic)
    {
        return rows
            .GroupBy(package => package.OfficeSize)
            .OrderBy(group => group.Min(package => package.DisplayOrder))
            .Select(group =>
            {
                var primary = group.OrderBy(package => package.BillingCycle).First();
                var monthly = group.FirstOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Monthly);
                var annual = group.FirstOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Annual);

                return new SubscriptionPackagePublicGroupDto
                {
                    OfficeSize = primary.OfficeSize.ToString(),
                    Name = GetLocalized(useArabic, primary.NameAr, primary.Name),
                    Description = GetLocalized(useArabic, primary.DescriptionAr, primary.Description),
                    Features = new[]
                    {
                        GetLocalized(useArabic, primary.Feature1Ar, primary.Feature1),
                        GetLocalized(useArabic, primary.Feature2Ar, primary.Feature2),
                        GetLocalized(useArabic, primary.Feature3Ar, primary.Feature3),
                    }.Where(feature => !string.IsNullOrWhiteSpace(feature)).ToArray(),
                    MonthlyOption = BuildOption(monthly),
                    AnnualOption = BuildOption(annual),
                    DisplayOrder = primary.DisplayOrder,
                };
            })
            .ToList();
    }

    private static IReadOnlyList<SubscriptionPackageAdminGroupDto> BuildAdminPackageGroups(IEnumerable<SubscriptionPackage> rows)
    {
        return rows
            .GroupBy(package => package.OfficeSize)
            .OrderBy(group => group.Min(package => package.DisplayOrder))
            .Select(group =>
            {
                var primary = group.OrderBy(package => package.BillingCycle).First();
                var monthly = group.FirstOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Monthly);
                var annual = group.FirstOrDefault(package => package.BillingCycle == SubscriptionBillingCycle.Annual);

                return new SubscriptionPackageAdminGroupDto
                {
                    OfficeSize = primary.OfficeSize.ToString(),
                    Name = primary.Name,
                    NameAr = primary.NameAr,
                    Description = primary.Description,
                    DescriptionAr = primary.DescriptionAr,
                    Feature1 = primary.Feature1,
                    Feature1Ar = primary.Feature1Ar,
                    Feature2 = primary.Feature2,
                    Feature2Ar = primary.Feature2Ar,
                    Feature3 = primary.Feature3,
                    Feature3Ar = primary.Feature3Ar,
                    MonthlyPackageId = monthly?.Id,
                    AnnualPackageId = annual?.Id,
                    MonthlyPrice = monthly?.Price ?? 0,
                    AnnualPrice = annual?.Price ?? 0,
                    Currency = primary.Currency,
                    IsActive = group.Any(package => package.IsActive),
                    DisplayOrder = primary.DisplayOrder,
                };
            })
            .ToList();
    }

    private static SubscriptionPackageCycleOptionDto? BuildOption(SubscriptionPackage? package)
    {
        return package == null
            ? null
            : new SubscriptionPackageCycleOptionDto
            {
                SubscriptionPackageId = package.Id,
                BillingCycle = package.BillingCycle.ToString(),
                Price = package.Price,
                Currency = package.Currency,
                IsActive = package.IsActive,
            };
    }

    private static string GetLocalized(bool useArabic, string preferred, string fallback)
    {
        return useArabic && !string.IsNullOrWhiteSpace(preferred) ? preferred : fallback;
    }

    private static string Normalize(string? value, string fallback = "")
    {
        return string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
    }
}
