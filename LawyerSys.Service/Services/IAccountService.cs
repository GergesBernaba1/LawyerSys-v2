using System;
using System.Threading.Tasks;

namespace LawyerSys.Services
{
    public interface IAccountService
    {
        Task<(string Token, DateTime Expires)> LoginAsync(LoginRequest model);
        Task<string> RequestPasswordResetAsync(string userNameOrEmail);
        Task ResetPasswordAsync(string userNameOrEmail, string token, string newPassword);
    }
}
