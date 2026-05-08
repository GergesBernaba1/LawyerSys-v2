using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Localization;
using LawyerSys.Resources;
using LawyerSys.Services.Subscriptions;

namespace LawyerSys.Services
{
    public class AccountService : IAccountService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _configuration;
        private readonly ApplicationDbContext _applicationDbContext;
        private readonly IStringLocalizer<SharedResource> _localizer;
        private readonly ITenantSubscriptionService _tenantSubscriptionService;

        public AccountService(
            UserManager<ApplicationUser> userManager,
            IConfiguration configuration,
            ApplicationDbContext applicationDbContext,
            IStringLocalizer<SharedResource> localizer,
            ITenantSubscriptionService tenantSubscriptionService)
        {
            _userManager = userManager;
            _configuration = configuration;
            _applicationDbContext = applicationDbContext;
            _localizer = localizer;
            _tenantSubscriptionService = tenantSubscriptionService;
        }

        public async Task<(string Token, string RefreshToken, DateTime Expires)> LoginAsync(LoginRequest model)
        {
            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null)
            {
                user = await _userManager.FindByEmailAsync(model.UserName);
            }

            if (user == null) throw new UnauthorizedAccessException("Invalid credentials");

            if (user.RequiresPasswordReset)
            {
                throw new InvalidOperationException(_localizer["PasswordResetRequiredMessage"].Value);
            }

            if (user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTimeOffset.UtcNow)
            {
                throw new InvalidOperationException(_localizer["AccountPendingActivationMessage"].Value);
            }

            var valid = await _userManager.CheckPasswordAsync(user, model.Password);
            if (!valid) throw new UnauthorizedAccessException("Invalid credentials");

            var tenant = await _applicationDbContext.Tenants
                .AsNoTracking()
                .SingleOrDefaultAsync(t => t.Id == user.TenantId);
            if (tenant == null)
            {
                throw new InvalidOperationException(_localizer["AccountTenantMissingMessage"].Value);
            }

            if (!tenant.IsActive)
            {
                throw new InvalidOperationException(_localizer["TenantInactiveMessage"].Value);
            }

            var roles = await _userManager.GetRolesAsync(user);
            await _tenantSubscriptionService.EnsureTenantCanLoginAsync(
                user,
                roles.Contains("SuperAdmin"),
                CancellationToken.None);

            var (accessToken, expires) = await CreateTokenAsync(user);
            var refreshToken = await GenerateAndStoreRefreshTokenAsync(user.Id);

            return (accessToken, refreshToken, expires);
        }

        public async Task<(string Token, DateTime Expires)> CreateTokenAsync(ApplicationUser user)
        {
            var jwtSection = _configuration.GetSection("Jwt");
            var key = Encoding.UTF8.GetBytes(jwtSection.GetValue<string>("Key") ?? "ChangeThisToASecureKey123!");
            var issuer = jwtSection.GetValue<string>("Issuer");
            var audience = jwtSection.GetValue<string>("Audience");
            var expireMinutes = jwtSection.GetValue<int>("ExpireMinutes");

            var tenant = await _applicationDbContext.Tenants
                .AsNoTracking()
                .SingleOrDefaultAsync(t => t.Id == user.TenantId);

            var roles = await _userManager.GetRolesAsync(user);

            var claimsList = new System.Collections.Generic.List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim("fullName", user.FullName ?? string.Empty),
            };

            foreach (var role in roles)
            {
                claimsList.Add(new Claim(ClaimTypes.Role, role));
            }

            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                claimsList.Add(new Claim(JwtRegisteredClaimNames.Email, user.Email));
                claimsList.Add(new Claim(ClaimTypes.Email, user.Email));
            }

            if (user.TenantId > 0)
            {
                claimsList.Add(new Claim("tenant_id", user.TenantId.ToString()));
                claimsList.Add(new Claim("firm_id", user.TenantId.ToString()));
                claimsList.Add(new Claim(ClaimTypes.GroupSid, user.TenantId.ToString()));
            }

            if (user.CountryId.HasValue && user.CountryId.Value > 0)
            {
                claimsList.Add(new Claim("country_id", user.CountryId.Value.ToString()));
            }

            if (tenant != null)
            {
                claimsList.Add(new Claim("tenant_name", tenant.Name));
                claimsList.Add(new Claim("tenant_active", tenant.IsActive ? "true" : "false"));
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

        public async Task<(string Token, string RefreshToken, DateTime Expires)> RefreshAsync(string refreshToken)
        {
            var tokenHash = HashToken(refreshToken);

            var stored = await _applicationDbContext.RefreshTokens
                .Include(rt => rt.User)
                .SingleOrDefaultAsync(rt => rt.TokenHash == tokenHash);

            if (stored == null || stored.IsRevoked || stored.ExpiresAtUtc < DateTime.UtcNow)
            {
                throw new UnauthorizedAccessException("Invalid or expired refresh token.");
            }

            var user = stored.User!;

            // Rotate: revoke current token
            stored.IsRevoked = true;

            // Issue new tokens
            var (accessToken, expires) = await CreateTokenAsync(user);
            var newRefreshToken = await GenerateAndStoreRefreshTokenAsync(user.Id);

            await _applicationDbContext.SaveChangesAsync();

            return (accessToken, newRefreshToken, expires);
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

        private async Task<string> GenerateAndStoreRefreshTokenAsync(string userId)
        {
            var jwtSection = _configuration.GetSection("Jwt");
            var expireDays = jwtSection.GetValue<int>("RefreshTokenExpireDays");
            if (expireDays <= 0) expireDays = 7;

            var rawToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
            var tokenHash = HashToken(rawToken);

            _applicationDbContext.RefreshTokens.Add(new RefreshToken
            {
                UserId = userId,
                TokenHash = tokenHash,
                ExpiresAtUtc = DateTime.UtcNow.AddDays(expireDays),
                IsRevoked = false,
                CreatedAtUtc = DateTime.UtcNow,
            });

            await _applicationDbContext.SaveChangesAsync();
            return rawToken;
        }

        private static string HashToken(string token)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToBase64String(bytes);
        }
    }
}
