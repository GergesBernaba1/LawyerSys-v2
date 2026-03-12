using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using LawyerSys.Services.Notifications;
using LawyerSys.Services.Subscriptions;

namespace LawyerSys.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TenantsController : ControllerBase
{
    private const string DefaultFirmName = "Default Firm";
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IInAppNotificationService _inAppNotificationService;
    private readonly ITenantSubscriptionService _tenantSubscriptionService;

    public TenantsController(
        ApplicationDbContext applicationDbContext,
        UserManager<ApplicationUser> userManager,
        IInAppNotificationService inAppNotificationService,
        ITenantSubscriptionService tenantSubscriptionService)
    {
        _applicationDbContext = applicationDbContext;
        _userManager = userManager;
        _inAppNotificationService = inAppNotificationService;
        _tenantSubscriptionService = tenantSubscriptionService;
    }

    [AllowAnonymous]
    [HttpGet("public-partners")]
    public async Task<IActionResult> GetPublicPartners()
    {
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var items = await _applicationDbContext.Tenants
            .AsNoTracking()
            .Include(tenant => tenant.Country)
            .Where(tenant => tenant.IsActive && tenant.Name != "Default Firm")
            .OrderBy(tenant => tenant.Name)
            .Select(tenant => new PublicTenantPartnerDto
            {
                Id = tenant.Id,
                Name = tenant.Name,
                CountryName = useArabic && tenant.Country != null && !string.IsNullOrWhiteSpace(tenant.Country.NameAr)
                    ? tenant.Country.NameAr
                    : tenant.Country != null ? tenant.Country.Name : string.Empty,
                UserCount = tenant.Users.Count,
            })
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("available")]
    public async Task<IActionResult> GetAvailableTenants()
    {
        var currentUser = await GetCurrentUserAsync();
        if (currentUser == null)
        {
            return Unauthorized(new { message = "User not found" });
        }

        var query = _applicationDbContext.Tenants
            .AsNoTracking()
            .Include(tenant => tenant.Country)
            .AsQueryable();

        if (!User.IsInRole("SuperAdmin"))
        {
            query = query.Where(tenant => tenant.Id == currentUser.TenantId);
        }

        var items = await query
            .OrderBy(tenant => tenant.Name)
            .Select(tenant => new TenantLookupDto
            {
                Id = tenant.Id,
                Name = tenant.Name,
                PhoneNumber = tenant.PhoneNumber,
                IsActive = tenant.IsActive,
                CountryId = tenant.CountryId,
                CountryName = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && tenant.Country != null && !string.IsNullOrWhiteSpace(tenant.Country.NameAr)
                    ? tenant.Country.NameAr
                    : tenant.Country != null ? tenant.Country.Name : string.Empty,
                UserCount = tenant.Users.Count,
                ContactEmail = tenant.ContactEmail,
                CurrentPackageName = tenant.Name == DefaultFirmName
                    ? string.Empty
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" &&
                            !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.NameAr)
                            ? subscription.SubscriptionPackage.NameAr
                            : subscription.SubscriptionPackage.Name)
                        .FirstOrDefault() ?? string.Empty,
                SubscriptionStatus = tenant.Name == DefaultFirmName
                    ? string.Empty
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => subscription.Status.ToString())
                        .FirstOrDefault() ?? string.Empty,
                SubscriptionEndDateUtc = tenant.Name == DefaultFirmName
                    ? null
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => (DateTime?)subscription.EndDateUtc)
                        .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(new TenantSelectionDto
        {
            CurrentTenantId = currentUser.TenantId,
            IsSuperAdmin = User.IsInRole("SuperAdmin"),
            Items = items
        });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet]
    public async Task<IActionResult> GetTenants()
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var tenants = await _applicationDbContext.Tenants
            .AsNoTracking()
            .Include(tenant => tenant.Country)
            .Include(tenant => tenant.Subscriptions)
                .ThenInclude(subscription => subscription.SubscriptionPackage)
            .OrderBy(tenant => tenant.Name)
            .Select(tenant => new TenantLookupDto
            {
                Id = tenant.Id,
                Name = tenant.Name,
                PhoneNumber = tenant.PhoneNumber,
                IsActive = tenant.IsActive,
                CountryId = tenant.CountryId,
                CountryName = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && tenant.Country != null && !string.IsNullOrWhiteSpace(tenant.Country.NameAr)
                    ? tenant.Country.NameAr
                    : tenant.Country != null ? tenant.Country.Name : string.Empty,
                UserCount = tenant.Users.Count,
                ContactEmail = tenant.ContactEmail,
                CurrentPackageName = tenant.Name == DefaultFirmName
                    ? string.Empty
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" &&
                            !string.IsNullOrWhiteSpace(subscription.SubscriptionPackage.NameAr)
                            ? subscription.SubscriptionPackage.NameAr
                            : subscription.SubscriptionPackage.Name)
                        .FirstOrDefault() ?? string.Empty,
                SubscriptionStatus = tenant.Name == DefaultFirmName
                    ? string.Empty
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => subscription.Status.ToString())
                        .FirstOrDefault() ?? string.Empty,
                SubscriptionEndDateUtc = tenant.Name == DefaultFirmName
                    ? null
                    : tenant.Subscriptions
                        .OrderByDescending(subscription => subscription.UpdatedAtUtc)
                        .Select(subscription => (DateTime?)subscription.EndDateUtc)
                        .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(tenants);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("{id:int}/status")]
    public async Task<IActionResult> UpdateTenantStatus(int id, [FromBody] UpdateTenantStatusRequest model)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return Forbid();
        }

        var tenant = await _applicationDbContext.Tenants.SingleOrDefaultAsync(item => item.Id == id);
        if (tenant == null)
        {
            return NotFound(new { message = "Tenant not found" });
        }

        var wasActive = tenant.IsActive;
        tenant.IsActive = model.IsActive;

        if (!wasActive && model.IsActive)
        {
            var adminUserIds = await (
                from user in _applicationDbContext.Users
                join userRole in _applicationDbContext.UserRoles on user.Id equals userRole.UserId
                join role in _applicationDbContext.Roles on userRole.RoleId equals role.Id
                where user.TenantId == tenant.Id && role.NormalizedName == "ADMIN"
                select user.Id
            ).Distinct().ToListAsync();

            if (adminUserIds.Count > 0)
            {
                var pendingAdmins = await _applicationDbContext.Users
                    .Where(user => adminUserIds.Contains(user.Id) && user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTimeOffset.UtcNow)
                    .ToListAsync();

                foreach (var pendingAdmin in pendingAdmins)
                {
                    pendingAdmin.LockoutEnabled = true;
                    pendingAdmin.LockoutEnd = null;
                }
            }
        }

        await _applicationDbContext.SaveChangesAsync();
        if (tenant.IsActive)
        {
            await _tenantSubscriptionService.ActivatePendingSubscriptionAsync(tenant.Id);
        }
        await _inAppNotificationService.NotifyTenantAdminsOfStatusChangeAsync(tenant, model.IsActive);
        return Ok(new { message = "Tenant status updated" });
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

public class TenantSelectionDto
{
    public int CurrentTenantId { get; set; }
    public bool IsSuperAdmin { get; set; }
    public IReadOnlyList<TenantLookupDto> Items { get; set; } = Array.Empty<TenantLookupDto>();
}

public class TenantLookupDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string ContactEmail { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int? CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public int UserCount { get; set; }
    public string CurrentPackageName { get; set; } = string.Empty;
    public string SubscriptionStatus { get; set; } = string.Empty;
    public DateTime? SubscriptionEndDateUtc { get; set; }
}

public class UpdateTenantStatusRequest
{
    public bool IsActive { get; set; }
}

public class PublicTenantPartnerDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
    public int UserCount { get; set; }
}
