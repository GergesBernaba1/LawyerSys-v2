using LawyerSys.Resources;
using LawyerSys.DTOs;
using LawyerSys.Services.Subscriptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using System.Globalization;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TenantSubscriptionsController : ControllerBase
{
    private const string DefaultFirmName = "Default Firm";
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITenantSubscriptionService _tenantSubscriptionService;
    private readonly IStringLocalizer<SharedResource> _localizer;

    public TenantSubscriptionsController(
        ApplicationDbContext applicationDbContext,
        UserManager<ApplicationUser> userManager,
        ITenantSubscriptionService tenantSubscriptionService,
        IStringLocalizer<SharedResource> localizer)
    {
        _applicationDbContext = applicationDbContext;
        _userManager = userManager;
        _tenantSubscriptionService = tenantSubscriptionService;
        _localizer = localizer;
    }

    [HttpGet("current")]
    public async Task<IActionResult> GetCurrentTenantSubscription()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser == null)
        {
            return Unauthorized(new { message = _localizer["UserNotFound"].Value });
        }

        var payload = await BuildTenantSubscriptionPayloadAsync(currentUser.TenantId, limitTransactions: 20);
        return payload == null
            ? NotFound(new { message = _localizer["SubscriptionNotFound"].Value })
            : Ok(payload);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("current/package")]
    public async Task<IActionResult> ChangeCurrentTenantPackage([FromBody] ChangeTenantPackageRequest request)
    {
        if (User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var currentUser = await GetCurrentUserAsync();
        if (currentUser == null)
        {
            return Unauthorized(new { message = _localizer["UserNotFound"].Value });
        }

        try
        {
            await _tenantSubscriptionService.ChangeTenantPackageAsync(currentUser.TenantId, request.SubscriptionPackageId);
            var payload = await BuildTenantSubscriptionPayloadAsync(currentUser.TenantId, limitTransactions: 20);
            return Ok(payload);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin/{tenantId:int}")]
    public async Task<IActionResult> GetAdminTenantSubscription(int tenantId)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var payload = await BuildTenantSubscriptionPayloadAsync(tenantId, limitTransactions: 50);
        return payload == null
            ? NotFound(new { message = _localizer["TenantNotFound"].Value })
            : Ok(payload);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("admin/{tenantId:int}/package")]
    public async Task<IActionResult> ChangeAdminTenantPackage(int tenantId, [FromBody] ChangeTenantPackageRequest request)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        try
        {
            var tenant = await _applicationDbContext.Tenants
                .AsNoTracking()
                .SingleOrDefaultAsync(item => item.Id == tenantId);

            if (tenant == null)
            {
                return NotFound(new { message = _localizer["TenantNotFound"].Value });
            }

            if (string.Equals(tenant.Name?.Trim(), DefaultFirmName, StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new { message = _localizer["DefaultFirmNoSubscriptions"].Value });
            }

            var existingSubscription = await _tenantSubscriptionService.GetCurrentSubscriptionAsync(tenantId);
            if (existingSubscription == null)
            {
                await _tenantSubscriptionService.CreateSubscriptionForTenantAsync(tenant, request.SubscriptionPackageId);
            }
            else
            {
                await _tenantSubscriptionService.ChangeTenantPackageAsync(tenantId, request.SubscriptionPackageId);
            }

            var payload = await BuildTenantSubscriptionPayloadAsync(tenantId, limitTransactions: 50);
            return payload == null
                ? NotFound(new { message = _localizer["TenantNotFound"].Value })
                : Ok(payload);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("admin")]
    public async Task<IActionResult> GetAdminBillingOverview([FromQuery] int? tenantId = null)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var tenantsQuery = _applicationDbContext.Tenants
            .AsNoTracking()
            .Where(tenant => tenant.Name != DefaultFirmName)
            .AsQueryable();

        if (tenantId.HasValue && tenantId.Value > 0)
        {
            tenantsQuery = tenantsQuery.Where(tenant => tenant.Id == tenantId.Value);
        }

        var tenantItems = await tenantsQuery
            .OrderBy(tenant => tenant.Name)
            .Select(tenant => new TenantSubscriptionSummaryDto
            {
                TenantId = tenant.Id,
                TenantName = tenant.Name,
                TenantEmail = tenant.ContactEmail,
                IsTenantActive = tenant.IsActive,
                PackageName = tenant.Subscriptions
                    .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                    .Select(subscription => useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.NameAr)
                        ? subscription.SubscriptionPackage.NameAr
                        : subscription.SubscriptionPackage.Name)
                    .FirstOrDefault() ?? string.Empty,
                Status = tenant.Subscriptions
                    .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                    .Select(subscription => subscription.Status.ToString())
                    .FirstOrDefault() ?? string.Empty,
                StartDateUtc = tenant.Subscriptions
                    .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                    .Select(subscription => (DateTime?)subscription.StartDateUtc)
                    .FirstOrDefault(),
                EndDateUtc = tenant.Subscriptions
                    .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                    .Select(subscription => (DateTime?)subscription.EndDateUtc)
                    .FirstOrDefault(),
                NextBillingDateUtc = tenant.Subscriptions
                    .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                    .Select(subscription => (DateTime?)subscription.NextBillingDateUtc)
                    .FirstOrDefault(),
            })
            .ToListAsync();

        var transactionsQuery = _applicationDbContext.TenantBillingTransactions
            .AsNoTracking()
            .Where(transaction => transaction.Tenant.Name != DefaultFirmName)
            .AsQueryable();

        if (tenantId.HasValue && tenantId.Value > 0)
        {
            transactionsQuery = transactionsQuery.Where(transaction => transaction.TenantId == tenantId.Value);
        }

        var transactions = await transactionsQuery
            .OrderByDescending(transaction => transaction.DueDateUtc)
            .Take(150)
            .Select(transaction => new TenantBillingTransactionDto
            {
                Id = transaction.Id,
                TenantId = transaction.TenantId,
                TenantName = transaction.Tenant.Name,
                PackageName = useArabic && !string.IsNullOrWhiteSpace(transaction.SubscriptionPackage.NameAr)
                    ? transaction.SubscriptionPackage.NameAr
                    : transaction.SubscriptionPackage.Name,
                BillingCycle = transaction.BillingCycle.ToString(),
                Status = transaction.Status.ToString(),
                Amount = transaction.Amount,
                Currency = transaction.Currency,
                DueDateUtc = transaction.DueDateUtc,
                PaidAtUtc = transaction.PaidAtUtc,
                PeriodStartUtc = transaction.PeriodStartUtc,
                PeriodEndUtc = transaction.PeriodEndUtc,
                Reference = transaction.Reference,
                Notes = transaction.Notes,
            })
            .ToListAsync();

        return Ok(new AdminTenantBillingOverviewDto
        {
            Tenants = tenantItems,
            Transactions = transactions,
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("admin/transactions/{id:long}/pay")]
    public async Task<IActionResult> MarkTransactionPaid(long id, [FromBody] UpdateTenantBillingTransactionStatusRequest? request)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        try
        {
            await _tenantSubscriptionService.MarkTransactionPaidAsync(id, request?.Reference, request?.Notes);
            return Ok(new { message = _localizer["TransactionMarkedPaid"].Value });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("admin/transactions/{id:long}/cancel")]
    public async Task<IActionResult> MarkTransactionCancelled(long id, [FromBody] UpdateTenantBillingTransactionStatusRequest? request)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        try
        {
            await _tenantSubscriptionService.MarkTransactionCancelledAsync(id, request?.Notes);
            return Ok(new { message = _localizer["TransactionCancelled"].Value });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private async Task<TenantSubscriptionDetailsDto?> BuildTenantSubscriptionPayloadAsync(int tenantId, int limitTransactions)
    {
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var subscription = await _applicationDbContext.TenantSubscriptions
            .AsNoTracking()
            .Include(item => item.SubscriptionPackage)
            .Include(item => item.Tenant)
            .Where(item => item.TenantId == tenantId)
            .OrderByDescending(item => item.UpdatedAtUtc)
            .FirstOrDefaultAsync();
        var tenant = subscription?.Tenant;
        if (tenant == null)
        {
            tenant = await _applicationDbContext.Tenants
                .AsNoTracking()
                .SingleOrDefaultAsync(item => item.Id == tenantId);
        }

        if (tenant == null)
        {
            return null;
        }

        if (string.Equals(tenant.Name?.Trim(), DefaultFirmName, StringComparison.OrdinalIgnoreCase))
        {
            return new TenantSubscriptionDetailsDto
            {
                HasSubscription = false,
                TenantId = tenant.Id,
                TenantName = tenant.Name,
                TenantEmail = tenant.ContactEmail,
                AvailablePackages = Array.Empty<SubscriptionPackagePublicGroupDto>(),
                Transactions = Array.Empty<TenantBillingTransactionDto>(),
            };
        }

        var transactions = subscription == null
            ? new List<TenantBillingTransactionDto>()
            : await _applicationDbContext.TenantBillingTransactions
                .AsNoTracking()
                .Include(item => item.SubscriptionPackage)
                .Where(item => item.TenantId == tenantId)
                .OrderByDescending(item => item.DueDateUtc)
                .Take(limitTransactions)
                .Select(transaction => new TenantBillingTransactionDto
                {
                    Id = transaction.Id,
                    TenantId = transaction.TenantId,
                    TenantName = tenant.Name,
                    PackageName = useArabic && !string.IsNullOrWhiteSpace(transaction.SubscriptionPackage.NameAr)
                        ? transaction.SubscriptionPackage.NameAr
                        : transaction.SubscriptionPackage.Name,
                    BillingCycle = transaction.BillingCycle.ToString(),
                    Status = transaction.Status.ToString(),
                    Amount = transaction.Amount,
                    Currency = transaction.Currency,
                    DueDateUtc = transaction.DueDateUtc,
                    PaidAtUtc = transaction.PaidAtUtc,
                    PeriodStartUtc = transaction.PeriodStartUtc,
                    PeriodEndUtc = transaction.PeriodEndUtc,
                    Reference = transaction.Reference,
                    Notes = transaction.Notes,
                })
                .ToListAsync();

        var availablePackages = await _applicationDbContext.SubscriptionPackages
            .AsNoTracking()
            .Where(package => package.IsActive)
            .OrderBy(package => package.DisplayOrder)
            .ToListAsync();

        return new TenantSubscriptionDetailsDto
        {
            HasSubscription = subscription != null,
            TenantId = tenant.Id,
            TenantName = tenant.Name,
            TenantEmail = tenant.ContactEmail,
            Status = subscription?.Status.ToString() ?? string.Empty,
            PackageId = subscription?.SubscriptionPackageId ?? 0,
            PackageName = subscription == null
                ? string.Empty
                : useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.NameAr)
                    ? subscription.SubscriptionPackage.NameAr
                    : subscription.SubscriptionPackage.Name,
            PackageDescription = subscription == null
                ? string.Empty
                : useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.DescriptionAr)
                    ? subscription.SubscriptionPackage.DescriptionAr
                    : subscription.SubscriptionPackage.Description,
            BillingCycle = subscription?.SubscriptionPackage.BillingCycle.ToString() ?? string.Empty,
            OfficeSize = subscription?.SubscriptionPackage.OfficeSize.ToString() ?? string.Empty,
            Price = subscription?.SubscriptionPackage.Price ?? 0,
            Currency = subscription?.SubscriptionPackage.Currency ?? string.Empty,
            PackageFeatures = subscription == null
                ? Array.Empty<string>()
                : new[]
                {
                    useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.Feature1Ar) ? subscription.SubscriptionPackage.Feature1Ar : subscription.SubscriptionPackage.Feature1,
                    useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.Feature2Ar) ? subscription.SubscriptionPackage.Feature2Ar : subscription.SubscriptionPackage.Feature2,
                    useArabic && !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.Feature3Ar) ? subscription.SubscriptionPackage.Feature3Ar : subscription.SubscriptionPackage.Feature3,
                }.Where(feature => !string.IsNullOrWhiteSpace(feature)).ToArray(),
            StartDateUtc = subscription?.StartDateUtc,
            EndDateUtc = subscription?.EndDateUtc,
            NextBillingDateUtc = subscription?.NextBillingDateUtc,
            Transactions = transactions,
            AvailablePackages = SubscriptionPackageMapper.BuildPublicGroups(availablePackages, useArabic),
        };
    }

    private async Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var currentUserId = _userManager.GetUserId(User);
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return null;
        }

        return await _applicationDbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(user => user.Id == currentUserId);
    }
}

public class TenantSubscriptionDetailsDto
{
    public bool HasSubscription { get; set; }
    public int TenantId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public string TenantEmail { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int PackageId { get; set; }
    public string PackageName { get; set; } = string.Empty;
    public string PackageDescription { get; set; } = string.Empty;
    public string BillingCycle { get; set; } = string.Empty;
    public string OfficeSize { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Currency { get; set; } = string.Empty;
    public IReadOnlyList<string> PackageFeatures { get; set; } = Array.Empty<string>();
    public DateTime? StartDateUtc { get; set; }
    public DateTime? EndDateUtc { get; set; }
    public DateTime? NextBillingDateUtc { get; set; }
    public IReadOnlyList<TenantBillingTransactionDto> Transactions { get; set; } = Array.Empty<TenantBillingTransactionDto>();
    public IReadOnlyList<SubscriptionPackagePublicGroupDto> AvailablePackages { get; set; } = Array.Empty<SubscriptionPackagePublicGroupDto>();
}

public class TenantSubscriptionSummaryDto
{
    public int TenantId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public string TenantEmail { get; set; } = string.Empty;
    public bool IsTenantActive { get; set; }
    public string PackageName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? StartDateUtc { get; set; }
    public DateTime? EndDateUtc { get; set; }
    public DateTime? NextBillingDateUtc { get; set; }
}

public class TenantBillingTransactionDto
{
    public long Id { get; set; }
    public int TenantId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public string PackageName { get; set; } = string.Empty;
    public string BillingCycle { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public DateTime DueDateUtc { get; set; }
    public DateTime? PaidAtUtc { get; set; }
    public DateTime PeriodStartUtc { get; set; }
    public DateTime PeriodEndUtc { get; set; }
    public string Reference { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
}

public class AdminTenantBillingOverviewDto
{
    public IReadOnlyList<TenantSubscriptionSummaryDto> Tenants { get; set; } = Array.Empty<TenantSubscriptionSummaryDto>();
    public IReadOnlyList<TenantBillingTransactionDto> Transactions { get; set; } = Array.Empty<TenantBillingTransactionDto>();
}

public class UpdateTenantBillingTransactionStatusRequest
{
    public string Reference { get; set; } = string.Empty;
    public string Notes { get; set; } = string.Empty;
}

public class ChangeTenantPackageRequest
{
    public int SubscriptionPackageId { get; set; }
}

internal static class SubscriptionPackageMapper
{
    public static IReadOnlyList<SubscriptionPackagePublicGroupDto> BuildPublicGroups(IEnumerable<SubscriptionPackage> rows, bool useArabic)
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
}
