using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using LawyerSys.Services;
using Serilog;
using Microsoft.EntityFrameworkCore;
using System.Globalization;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IAccountService _accountService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ApplicationDbContext _applicationDbContext;

    public AccountController(
        IAccountService accountService,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        ApplicationDbContext applicationDbContext)
    {
        _accountService = accountService;
        _userManager = userManager;
        _roleManager = roleManager;
        _applicationDbContext = applicationDbContext;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
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

        var user = new ApplicationUser { 
            UserName = model.UserName, 
            Email = model.Email, 
            FullName = model.FullName,
            CountryId = model.CountryId,
            EmailConfirmed = false, 
            RequiresPasswordReset = false 
        };
        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);

        // Optionally add claims/roles here
        return Ok(new { message = "User created." });
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
            CountryName = GetLocalizedName(user.Country?.Name, user.Country?.NameAr)
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
                    .FirstOrDefaultAsync() ?? string.Empty
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
        var users = await _userManager.Users
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
                RequiresPasswordReset = user.RequiresPasswordReset,
                IsEnabled = !isDisabled,
                Roles = roles.ToArray()
            });
        }

        return Ok(result);
    }

    [Authorize(Policy = "AdminOnly")]
    [HttpPost("users/{id}/enable")]
    public async Task<IActionResult> EnableUser(string id)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

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
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

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
        var user = await _userManager.FindByIdAsync(id);
        if (user == null) return NotFound(new { message = "User not found" });

        var requestedRoles = (model.Roles ?? Array.Empty<string>())
            .Where(r => !string.IsNullOrWhiteSpace(r))
            .Select(r => r.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        foreach (var role in requestedRoles)
        {
            if (!await _roleManager.RoleExistsAsync(role))
            {
                return BadRequest(new { message = $"Role '{role}' does not exist." });
            }
        }

        var currentRoles = await _userManager.GetRolesAsync(user);
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
            .Include(user => user.Country)
            .SingleOrDefaultAsync(user => user.Id == currentUserId);
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
}

public class UpdateMyProfileRequest
{
    public string UserName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public int? CountryId { get; set; }
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
