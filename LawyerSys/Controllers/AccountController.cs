using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/[controller]")]
public class AccountController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly IConfiguration _configuration;

    public AccountController(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager, IConfiguration configuration)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest model)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var user = new ApplicationUser { UserName = model.UserName, Email = model.Email, EmailConfirmed = false, RequiresPasswordReset = false };
        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);

        // Optionally add claims/roles here
        return Ok(new { message = "User created." });
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest model)
    {
        Console.WriteLine($"Login attempt for user: {model.UserName}");
        
        if (!ModelState.IsValid) 
        {
            Console.WriteLine("Model state invalid");
            return BadRequest(ModelState);
        }

        var user = await _userManager.FindByNameAsync(model.UserName);
        Console.WriteLine($"User found: {user != null}");
        
        if (user == null) 
        {
            Console.WriteLine("User not found");
            return Unauthorized(new { message = "Invalid credentials" });
        }

        // If the user was migrated and must reset password, block login and instruct reset
        if (user.RequiresPasswordReset)
        {
            Console.WriteLine("Password reset required");
            return StatusCode(403, new { message = "Password reset required. Please reset your password before logging in." });
        }

        var valid = await _userManager.CheckPasswordAsync(user, model.Password);
        Console.WriteLine($"Password valid: {valid}");
        
        if (!valid) 
        {
            Console.WriteLine("Invalid password");
            return Unauthorized(new { message = "Invalid credentials" });
        }

        var jwtSection = _configuration.GetSection("Jwt");
        var key = Encoding.UTF8.GetBytes(jwtSection.GetValue<string>("Key") ?? "ChangeThisToASecureKey123!");
        var issuer = jwtSection.GetValue<string>("Issuer");
        var audience = jwtSection.GetValue<string>("Audience");
        var expireMinutes = jwtSection.GetValue<int>("ExpireMinutes");

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expireMinutes <= 0 ? 60 : expireMinutes),
            signingCredentials: new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256)
        );

        var jwt = new JwtSecurityTokenHandler().WriteToken(token);
        return Ok(new { token = jwt, expires = token.ValidTo });
    }

        [HttpPost("request-password-reset")]
        [AllowAnonymous]
        public async Task<IActionResult> RequestPasswordReset([FromBody] RequestPasswordResetRequest model)
        {
            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null) return NotFound(new { message = "User not found" });

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            // In a real system we would email this token; for now return it in the response for manual testing
            return Ok(new { userId = user.Id, token });
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest model)
        {
            Console.WriteLine($"Reset password attempt for user: {model.UserName}");
            
            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null)
            {
                Console.WriteLine("User not found for password reset");
                return NotFound(new { message = "User not found" });
            }

            Console.WriteLine($"User found: {user.UserName}, attempting reset with token");
            var result = await _userManager.ResetPasswordAsync(user, model.Token, model.NewPassword);
            
            if (!result.Succeeded)
            {
                Console.WriteLine($"Password reset failed: {string.Join(", ", result.Errors.Select(e => e.Description))}");
                return BadRequest(result.Errors);
            }

            Console.WriteLine("Password reset successful, clearing RequiresPasswordReset flag");
            // Clear the migration flag if present
            user.RequiresPasswordReset = false;
            await _userManager.UpdateAsync(user);
            
            // Update security stamp to invalidate old tokens
            await _userManager.UpdateSecurityStampAsync(user);
            
            Console.WriteLine("Password reset complete");
            return Ok(new { message = "Password updated" });
        }
}

public class RegisterRequest
{
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
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

public class LoginRequest
{
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
