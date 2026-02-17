using System.Threading.Tasks;

namespace LawyerSys.Services.Email;

public interface IEmailSender
{
    Task SendEmailAsync(string to, string subject, string body);
}
