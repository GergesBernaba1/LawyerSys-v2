using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using LawyerSys.Services;
using LawyerSys.Services.Email;
using LawyerSys.Services.Notifications;
using Serilog;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using System.Security.Claims;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IAccountService _accountService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ApplicationDbContext _applicationDbContext;
    private readonly IEmailSender _emailSender;
    private readonly IStringLocalizer<SharedResource> _localizer;
    private readonly IInAppNotificationService _inAppNotificationService;

    public AccountController(
        IAccountService accountService,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        ApplicationDbContext applicationDbContext,
        IEmailSender emailSender,
        IStringLocalizer<SharedResource> localizer,
        IInAppNotificationService inAppNotificationService)
    {
        _accountService = accountService;
        _userManager = userManager;
        _roleManager = roleManager;
        _applicationDbContext = applicationDbContext;
        _emailSender = emailSender;
        _localizer = localizer;
        _inAppNotificationService = inAppNotificationService;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        model.UserName = (model.UserName ?? string.Empty).Trim();
        model.Email = (model.Email ?? string.Empty).Trim();
        model.FullName = (model.FullName ?? string.Empty).Trim();
        model.LawyerOfficeName = (model.LawyerOfficeName ?? string.Empty).Trim();
        model.LawyerOfficePhoneNumber = (model.LawyerOfficePhoneNumber ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(model.LawyerOfficeName))
        {
            return BadRequest(new { message = "Lawyer office name is required." });
        }
        if (string.IsNullOrWhiteSpace(model.LawyerOfficePhoneNumber))
        {
            return BadRequest(new { message = "Lawyer office phone number is required." });
        }
        if (model.CountryId is null or <= 0)
        {
            return BadRequest(new { message = "Country is required." });
        }

        var countryExists = await _applicationDbContext.Countries
            .AnyAsync(country => country.Id == model.CountryId.Value);
        if (!countryExists)
        {
            return BadRequest(new { message = "Selected country is invalid." });
        }

        var duplicateFields = new List<string>();
        var normalizedUserName = _userManager.NormalizeName(model.UserName);
        if (!string.IsNullOrWhiteSpace(normalizedUserName))
        {
            var userNameExists = await _applicationDbContext.Users
                .AsNoTracking()
                .AnyAsync(user => user.NormalizedUserName == normalizedUserName);
            if (userNameExists)
            {
                duplicateFields.Add(_localizer["RegistrationFieldUserName"].Value);
            }
        }

        var normalizedEmail = _userManager.NormalizeEmail(model.Email);
        if (!string.IsNullOrWhiteSpace(normalizedEmail))
        {
            var emailExists = await _applicationDbContext.Users
                .AsNoTracking()
                .AnyAsync(user => user.NormalizedEmail == normalizedEmail);
            if (emailExists)
            {
                duplicateFields.Add(_localizer["RegistrationFieldEmail"].Value);
            }
        }

        var phoneExists = await _applicationDbContext.Users
            .AsNoTracking()
            .AnyAsync(user => user.PhoneNumber == model.LawyerOfficePhoneNumber);
        if (phoneExists)
        {
            duplicateFields.Add(_localizer["RegistrationFieldPhone"].Value);
        }

        if (duplicateFields.Count == 1)
        {
            return BadRequest(new
            {
                message = _localizer["RegistrationFieldAlreadyUsedMessage", duplicateFields[0]].Value
            });
        }

        if (duplicateFields.Count > 1)
        {
            return BadRequest(new
            {
                message = _localizer["RegistrationFieldsAlreadyUsedMessage", string.Join(", ", duplicateFields)].Value
            });
        }

        await using var transaction = await _applicationDbContext.Database.BeginTransactionAsync();

        var tenant = new Tenant
        {
            Name = model.LawyerOfficeName.Trim(),
            PhoneNumber = model.LawyerOfficePhoneNumber.Trim(),
            CountryId = model.CountryId,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        _applicationDbContext.Tenants.Add(tenant);
        await _applicationDbContext.SaveChangesAsync();

        var user = new ApplicationUser
        {
            UserName = model.UserName,
            Email = model.Email,
            FullName = model.FullName,
            PhoneNumber = model.LawyerOfficePhoneNumber.Trim(),
            CountryId = model.CountryId,
            TenantId = tenant.Id,
            LockoutEnabled = true,
            LockoutEnd = DateTimeOffset.MaxValue,
            EmailConfirmed = false,
            RequiresPasswordReset = false
        };

        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded)
        {
            await transaction.RollbackAsync();
            return BadRequest(result.Errors);
        }

        if (!await _roleManager.RoleExistsAsync("Admin"))
        {
            await _roleManager.CreateAsync(new IdentityRole("Admin"));
        }

        var roleResult = await _userManager.AddToRoleAsync(user, "Admin");
        if (!roleResult.Succeeded)
        {
            await transaction.RollbackAsync();
            return BadRequest(roleResult.Errors);
        }

        await transaction.CommitAsync();

        try
        {
            await _inAppNotificationService.NotifySuperAdminsOfTenantRegistrationAsync(tenant, user);

            var countryName = await _applicationDbContext.Countries
                .AsNoTracking()
                .Where(country => country.Id == model.CountryId.Value)
                .Select(country => GetLocalizedName(country.Name, country.NameAr))
                .FirstOrDefaultAsync() ?? "Unknown";

            var subject = _localizer["RegistrationNotificationSubject"].Value;
            var template = _localizer["RegistrationNotificationBody"].Value;
            var body = template
                .Replace("{FullName}", System.Net.WebUtility.HtmlEncode(model.FullName ?? string.Empty))
                .Replace("{UserName}", System.Net.WebUtility.HtmlEncode(model.UserName ?? string.Empty))
                .Replace("{Email}", System.Net.WebUtility.HtmlEncode(model.Email ?? string.Empty))
                .Replace("{OfficeName}", System.Net.WebUtility.HtmlEncode(model.LawyerOfficeName ?? string.Empty))
                .Replace("{OfficePhone}", System.Net.WebUtility.HtmlEncode(model.LawyerOfficePhoneNumber ?? string.Empty))
                .Replace("{Country}", System.Net.WebUtility.HtmlEncode(countryName))
                .Replace("{TenantId}", tenant.Id.ToString(CultureInfo.InvariantCulture))
                .Replace("{RegisteredAtUtc}", DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture));

            await _emailSender.SendEmailAsync("gergesbernaba2@gmail.com", subject, body);
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "User registration succeeded but notification email failed for {Email}", model.Email);
        }

        return Ok(new { message = _localizer["RegistrationPendingActivationMessage"].Value });
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest model)
    {
        Log.Information("Login attempt for user: {UserName}", model.UserName);
        
        if (!ModelState.IsValid) 
        {
            Log.Warning("Model state invalid during login attempt");
            return BadRequest(ModelState);
        }

        try
        {
            var (token, expires) = await _accountService.LoginAsync(model);
            return Ok(new { token, expires });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(403, new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { message = "Invalid credentials" });
        }
    }

    [HttpGet("countries")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCountries()
    {
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        var countries = await _applicationDbContext.Countries
            .AsNoTracking()
            .OrderBy(country => country.Name)
            .Select(country => new CountryLookupDto
            {
                Id = country.Id,
                Name = useArabic && !string.IsNullOrWhiteSpace(country.NameAr)
                    ? country.NameAr
                    : country.Name,
                NameEn = country.Name,
                NameAr = country.NameAr
            })
            .ToListAsync();

        return Ok(countries);
    }

        [HttpPost("request-password-reset")]
        [AllowAnonymous]
        public async Task<IActionResult> RequestPasswordReset([FromBody] RequestPasswordResetRequest model)
        {
            try
            {
                var token = await _accountService.RequestPasswordResetAsync(model.UserName);
                // In a real system we would email this token; for now return it in the response for manual testing
                return Ok(new { token });
            }
            catch (ArgumentException)
            {
                return NotFound(new { message = "User not found" });
            }
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest model)
        {
            try
            {
                await _accountService.ResetPasswordAsync(model.UserName, model.Token, model.NewPassword);
                return Ok(new { message = "Password updated" });
            }
            catch (ArgumentException)
            {
                return NotFound(new { message = "User not found" });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        var user = await GetCurrentUserAsync();
        if (user == null) return Unauthorized(new { message = "User not found" });

        return Ok(new AccountProfileDto
        {
            UserName = user.UserName ?? string.Empty,
            FullName = user.FullName ?? string.Empty,
            Email = user.Email ?? string.Empty,
            PhoneNumber = user.PhoneNumber ?? string.Empty,
            CountryId = user.CountryId,
            CountryName = GetLocalizedName(user.Country?.Name, user.Country?.NameAr),
            TenantId = user.TenantId,
            TenantName = user.Tenant?.Name ?? string.Empty,
            TenantPhoneNumber = user.Tenant?.PhoneNumber ?? string.Empty,
            CanManageTenant = await UserCanManageTenantAsync(user)
        });
    }

    [Authorize]
    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateMyProfileRequest model)
    {
        var user = await GetCurrentUserAsync();
        if (user == null) return Unauthorized(new { message = "User not found" });

        var requestedUserName = (model.UserName ?? string.Empty).Trim();
        var requestedEmail = (model.Email ?? string.Empty).Trim();
        var requestedFullName = (model.FullName ?? string.Empty).Trim();
        var requestedPhoneNumber = (model.PhoneNumber ?? string.Empty).Trim();
        var requestedCountryId = model.CountryId;
        var requestedTenantName = (model.TenantName ?? string.Empty).Trim();
        var requestedTenantPhoneNumber = (model.TenantPhoneNumber ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(requestedUserName))
            return BadRequest(new { message = "Username is required." });
        if (string.IsNullOrWhiteSpace(requestedEmail))
            return BadRequest(new { message = "Email is required." });
        if (string.IsNullOrWhiteSpace(requestedFullName))
            return BadRequest(new { message = "Full name is required." });
        if (requestedCountryId is null or <= 0)
            return BadRequest(new { message = "Country is required." });

        var countryExists = await _applicationDbContext.Countries
            .AnyAsync(country => country.Id == requestedCountryId.Value);
        if (!countryExists)
        {
            return BadRequest(new { message = "Selected country is invalid." });
        }

        if (!string.Equals(user.UserName, requestedUserName, StringComparison.OrdinalIgnoreCase))
        {
            var existingUser = await _userManager.FindByNameAsync(requestedUserName);
            if (existingUser != null && !string.Equals(existingUser.Id, user.Id, StringComparison.Ordinal))
            {
                return BadRequest(new { message = "Username is already in use." });
            }
        }

        if (!string.Equals(user.Email, requestedEmail, StringComparison.OrdinalIgnoreCase))
        {
            var existingEmailUser = await _userManager.FindByEmailAsync(requestedEmail);
            if (existingEmailUser != null && !string.Equals(existingEmailUser.Id, user.Id, StringComparison.Ordinal))
            {
                return BadRequest(new { message = "Email is already in use." });
            }
        }

        user.UserName = requestedUserName;
        user.Email = requestedEmail;
        user.FullName = requestedFullName;
        user.PhoneNumber = string.IsNullOrWhiteSpace(requestedPhoneNumber) ? null : requestedPhoneNumber;
        user.CountryId = requestedCountryId;

        if (await UserCanManageTenantAsync(user))
        {
            if (user.Tenant == null)
            {
                user.Tenant = await _applicationDbContext.Tenants.SingleOrDefaultAsync(tenant => tenant.Id == user.TenantId);
            }

            if (user.Tenant != null)
            {
                if (!string.IsNullOrWhiteSpace(requestedTenantName))
                {
                    user.Tenant.Name = requestedTenantName;
                }

                if (!string.IsNullOrWhiteSpace(requestedTenantPhoneNumber))
                {
                    user.Tenant.PhoneNumber = requestedTenantPhoneNumber;
                }

                user.Tenant.CountryId = requestedCountryId;
            }
        }

        var updateResult = await _userManager.UpdateAsync(user);
        if (!updateResult.Succeeded)
        {
            return BadRequest(new { message = BuildIdentityErrors(updateResult.Errors) });
        }

        var (token, expires) = await _accountService.CreateTokenAsync(user);
        var useArabic = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar";
        return Ok(new
        {
            message = "Profile updated",
            token,
            expires,
            profile = new AccountProfileDto
            {
                UserName = user.UserName ?? string.Empty,
                FullName = user.FullName ?? string.Empty,
                Email = user.Email ?? string.Empty,
                PhoneNumber = user.PhoneNumber ?? string.Empty,
                CountryId = user.CountryId,
                CountryName = await _applicationDbContext.Countries
                    .Where(country => country.Id == user.CountryId)
                    .Select(country => useArabic && !string.IsNullOrWhiteSpace(country.NameAr)
                        ? country.NameAr
                        : country.Name)
                    .FirstOrDefaultAsync() ?? string.Empty,
                TenantId = user.TenantId,
                TenantName = user.Tenant?.Name ?? string.Empty,
                TenantPhoneNumber = user.Tenant?.PhoneNumber ?? string.Empty,
                CanManageTenant = await UserCanManageTenantAsync(user)
            }
        });
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangeMyPassword([FromBody] ChangePasswordRequest model)
    {
        var user = await GetCurrentUserAsync();
        if (user == null) return Unauthorized(new { message = "User not found" });

        if (string.IsNullOrWhiteSpace(model.CurrentPassword))
            return BadRequest(new { message = "Current password is required." });
        if (string.IsNullOrWhiteSpace(model.NewPassword))
            return BadRequest(new { message = "New password is required." });

        var result = await _userManager.ChangePasswordAsync(user, model.CurrentPassword, model.NewPassword);
        if (!result.Succeeded)
        {
            return BadRequest(new { message = BuildIdentityErrors(result.Errors) });
        }

        await _userManager.UpdateSecurityStampAsync(user);
        return Ok(new { message = "Password updated" });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("users")]
    public async Task<IActionResult> GetIdentityUsers()
    {
        var requestedTenantId = GetRequestedTenantId();
        var currentUser = await GetCurrentUserAsync();
        if (currentUser == null)
        {
            return Unauthorized(new { message = "User not found" });
        }

        var query = _userManager.Users
            .Include(u => u.Tenant)
            .AsQueryable();

        if (User.IsInRole("SuperAdmin"))
        {
            if (requestedTenantId.HasValue)
            {
                query = query.Where(user => user.TenantId == requestedTenantId.Value);
            }
        }
        else
        {
            query = query.Where(user => user.TenantId == currentUser.TenantId);
        }

        var users = await query
            .OrderBy(u => u.UserName)
            .ToListAsync();

        var result = new List<IdentityUserManagementDto>(users.Count);
        foreach (var user in users)
        {
            var roles = await _userManager.GetRolesAsync(user);
            var isDisabled = user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTimeOffset.UtcNow;
            result.Add(new IdentityUserManagementDto
            {
                Id = user.Id,
                UserName = user.UserName ?? string.Empty,
                Email = user.Email ?? string.Empty,
                FullName = user.FullName,
                TenantId = user.TenantId,
                TenantName = user.Tenant?.Name ?? string.Empty,
                RequiresPasswordReset = user.RequiresPasswordReset,
                IsEnabled = !isDisabled,
                Roles = roles.ToArray()
            });
        }

        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpGet("users/roles")]
    public async Task<IActionResult> GetAvailableRoles()
    {
        var roles = await _roleManager.Roles
            .AsNoTracking()
            .Where(role => role.NormalizedName != "SUPERADMIN")
            .OrderBy(role => role.Name)
            .Select(role => role.Name ?? string.Empty)
            .Where(roleName => !string.IsNullOrWhiteSpace(roleName))
            .ToListAsync();

        return Ok(roles);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("users/{id}/enable")]
    public async Task<IActionResult> EnableUser(string id)
    {
        var user = await FindAccessibleUserAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

        var userRoles = await _userManager.GetRolesAsync(user);
        if (!User.IsInRole("SuperAdmin") && userRoles.Contains("SuperAdmin"))
        {
            return Forbid();
        }

        user.LockoutEnabled = true;
        user.LockoutEnd = null;
        var update = await _userManager.UpdateAsync(user);
        if (!update.Succeeded) return BadRequest(update.Errors);

        await _userManager.UpdateSecurityStampAsync(user);
        return Ok(new { message = "User enabled" });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("users/{id}/disable")]
    public async Task<IActionResult> DisableUser(string id)
    {
        var user = await FindAccessibleUserAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

        var userRoles = await _userManager.GetRolesAsync(user);
        if (!User.IsInRole("SuperAdmin") && userRoles.Contains("SuperAdmin"))
        {
            return Forbid();
        }

        var currentUserId = _userManager.GetUserId(User);
        if (!string.IsNullOrWhiteSpace(currentUserId) && currentUserId == user.Id)
        {
            return BadRequest(new { message = "You cannot disable your own account." });
        }

        user.LockoutEnabled = true;
        user.LockoutEnd = DateTimeOffset.MaxValue;
        var update = await _userManager.UpdateAsync(user);
        if (!update.Succeeded) return BadRequest(update.Errors);

        await _userManager.UpdateSecurityStampAsync(user);
        return Ok(new { message = "User disabled" });
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPut("users/{id}/roles")]
    public async Task<IActionResult> SetUserRoles(string id, [FromBody] SetUserRolesRequest model)
    {
        var user = await FindAccessibleUserAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

        var currentUserId = _userManager.GetUserId(User);
        if (!string.IsNullOrWhiteSpace(currentUserId) && currentUserId == user.Id)
        {
            return BadRequest(new { message = "You cannot change your own roles." });
        }

        var currentRoles = await _userManager.GetRolesAsync(user);

        if (!User.IsInRole("SuperAdmin") && currentRoles.Contains("SuperAdmin"))
        {
            return Forbid();
        }

        var requestedRoles = (model.Roles ?? Array.Empty<string>())
            .Where(r => !string.IsNullOrWhiteSpace(r))
            .Select(r => r.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        if (requestedRoles.Contains("SuperAdmin", StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "The SuperAdmin role cannot be assigned." });
        }

        foreach (var role in requestedRoles)
        {
            if (!await _roleManager.RoleExistsAsync(role))
            {
                return BadRequest(new { message = $"Role '{role}' does not exist." });
            }
        }

        var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
        if (!removeResult.Succeeded) return BadRequest(removeResult.Errors);

        if (requestedRoles.Length > 0)
        {
            var addResult = await _userManager.AddToRolesAsync(user, requestedRoles);
            if (!addResult.Succeeded) return BadRequest(addResult.Errors);
        }

        await _userManager.UpdateSecurityStampAsync(user);
        return Ok(new { message = "User roles updated" });
    }

    private async Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var currentUserId = _userManager.GetUserId(User);
        if (string.IsNullOrWhiteSpace(currentUserId))
        {
            return null;
        }

        return await _applicationDbContext.Users
            .Include(user => user.Tenant)
            .Include(user => user.Country)
            .SingleOrDefaultAsync(user => user.Id == currentUserId);
    }

    private int? GetRequestedTenantId()
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            return null;
        }

        var headerValue = Request.Headers["X-Firm-Id"].FirstOrDefault();
        return int.TryParse(headerValue, out var tenantId) && tenantId > 0
            ? tenantId
            : null;
    }

    private async Task<ApplicationUser?> FindAccessibleUserAsync(string id)
    {
        var targetUser = await _applicationDbContext.Users
            .Include(user => user.Tenant)
            .SingleOrDefaultAsync(user => user.Id == id);
        if (targetUser == null)
        {
            return null;
        }

        if (User.IsInRole("SuperAdmin"))
        {
            var requestedTenantId = GetRequestedTenantId();
            if (requestedTenantId.HasValue && targetUser.TenantId != requestedTenantId.Value)
            {
                return null;
            }

            return targetUser;
        }

        var currentUser = await GetCurrentUserAsync();
        return currentUser != null && targetUser.TenantId == currentUser.TenantId
            ? targetUser
            : null;
    }

    private async Task<bool> UserCanManageTenantAsync(ApplicationUser user)
    {
        var roles = await _userManager.GetRolesAsync(user);
        return roles.Contains("Admin") || roles.Contains("SuperAdmin");
    }

    private static string BuildIdentityErrors(IEnumerable<IdentityError> errors)
    {
        return string.Join(", ", errors.Select(e => e.Description));
    }

    private static string GetLocalizedName(string? nameEn, string? nameAr)
    {
        return CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ar" && !string.IsNullOrWhiteSpace(nameAr)
            ? nameAr
            : nameEn ?? string.Empty;
    }
}

public class IdentityUserManagementDto
{
    public string Id { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public int TenantId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public bool RequiresPasswordReset { get; set; }
    public bool IsEnabled { get; set; }
    public string[] Roles { get; set; } = Array.Empty<string>();
}

public class SetUserRolesRequest
{
    public string[] Roles { get; set; } = Array.Empty<string>();
}

public class AccountProfileDto
{
    public string UserName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public int? CountryId { get; set; }
    public string CountryName { get; set; } = string.Empty;
    public int TenantId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public string TenantPhoneNumber { get; set; } = string.Empty;
    public bool CanManageTenant { get; set; }
}

public class UpdateMyProfileRequest
{
    public string UserName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public int? CountryId { get; set; }
    public string TenantName { get; set; } = string.Empty;
    public string TenantPhoneNumber { get; set; } = string.Empty;
}

public class ChangePasswordRequest
{
    public string CurrentPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

public class RegisterRequest
{
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public int? CountryId { get; set; }
    public string LawyerOfficeName { get; set; } = string.Empty;
    public string LawyerOfficePhoneNumber { get; set; } = string.Empty;
}

public class CountryLookupDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
}

public class RequestPasswordResetRequest
{
    public string UserName { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    public string UserName { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
