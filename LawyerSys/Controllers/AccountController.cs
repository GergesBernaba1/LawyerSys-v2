using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using LawyerSys.Services;
using Serilog;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly IAccountService _accountService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;

    public AccountController(IAccountService accountService, UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager)
    {
        _accountService = accountService;
        _userManager = userManager;
        _roleManager = roleManager;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = new ApplicationUser { 
            UserName = model.UserName, 
            Email = model.Email, 
            FullName = model.FullName,
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

public class RegisterRequest
{
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
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
