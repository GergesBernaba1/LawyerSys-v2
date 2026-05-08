using System;
using System.Threading.Tasks;

namespace LawyerSys.Services
{
    public interface IAccountService
    {
        Task<(string Token, string RefreshToken, DateTime Expires)> LoginAsync(LoginRequest model);
        Task<(string Token, DateTime Expires)> CreateTokenAsync(ApplicationUser user);
        Task<(string Token, string RefreshToken, DateTime Expires)> RefreshAsync(string refreshToken);
        Task<string> RequestPasswordResetAsync(string userNameOrEmail);
        Task ResetPasswordAsync(string userNameOrEmail, string token, string newPassword);
    }
}
