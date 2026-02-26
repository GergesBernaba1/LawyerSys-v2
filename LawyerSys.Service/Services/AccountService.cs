using System;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;

namespace LawyerSys.Services
{
    public class AccountService : IAccountService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _configuration;

        public AccountService(UserManager<ApplicationUser> userManager, IConfiguration configuration)
        {
            _userManager = userManager;
            _configuration = configuration;
        }

        public async Task<(string Token, DateTime Expires)> LoginAsync(LoginRequest model)
        {
            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null)
            {
                user = await _userManager.FindByEmailAsync(model.UserName);
            }

            if (user == null) throw new UnauthorizedAccessException("Invalid credentials");

            if (user.RequiresPasswordReset)
            {
                throw new InvalidOperationException("Password reset required. Please reset your password before logging in.");
            }

            if (user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTimeOffset.UtcNow)
            {
                throw new InvalidOperationException("Account is disabled. Contact an administrator.");
            }

            var valid = await _userManager.CheckPasswordAsync(user, model.Password);
            if (!valid) throw new UnauthorizedAccessException("Invalid credentials");

            var jwtSection = _configuration.GetSection("Jwt");
            var key = Encoding.UTF8.GetBytes(jwtSection.GetValue<string>("Key") ?? "ChangeThisToASecureKey123!");
            var issuer = jwtSection.GetValue<string>("Issuer");
            var audience = jwtSection.GetValue<string>("Audience");
            var expireMinutes = jwtSection.GetValue<int>("ExpireMinutes");

            // Get user roles
            var roles = await _userManager.GetRolesAsync(user);

            var claimsList = new System.Collections.Generic.List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
                new Claim("fullName", user.FullName ?? string.Empty),
            };

            // Add role claims
            foreach (var role in roles)
            {
                claimsList.Add(new Claim(ClaimTypes.Role, role));
            }

            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                claimsList.Add(new Claim(JwtRegisteredClaimNames.Email, user.Email));
            }

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claimsList,
                expires: DateTime.UtcNow.AddMinutes(expireMinutes <= 0 ? 60 : expireMinutes),
                signingCredentials: new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256)
            );

            var jwt = new JwtSecurityTokenHandler().WriteToken(token);
            return (jwt, token.ValidTo);
        }

        public async Task<string> RequestPasswordResetAsync(string userNameOrEmail)
        {
            var user = await _userManager.FindByNameAsync(userNameOrEmail) ?? await _userManager.FindByEmailAsync(userNameOrEmail);
            if (user == null) throw new ArgumentException("User not found");

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            return token;
        }

        public async Task ResetPasswordAsync(string userNameOrEmail, string token, string newPassword)
        {
            var user = await _userManager.FindByNameAsync(userNameOrEmail) ?? await _userManager.FindByEmailAsync(userNameOrEmail);
            if (user == null) throw new ArgumentException("User not found");

            var result = await _userManager.ResetPasswordAsync(user, token, newPassword);
            if (!result.Succeeded) throw new InvalidOperationException(string.Join(", ", result.Errors));

            user.RequiresPasswordReset = false;
            await _userManager.UpdateAsync(user);
            await _userManager.UpdateSecurityStampAsync(user);
        }
    }
}
