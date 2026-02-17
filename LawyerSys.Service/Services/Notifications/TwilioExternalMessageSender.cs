using Microsoft.Extensions.Options;
using Serilog;
using System.Net.Http.Headers;
using System.Text;

namespace LawyerSys.Services.Notifications;

public class TwilioExternalMessageSender : IExternalMessageSender
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IOptions<NotificationChannelsOptions> _options;

    public TwilioExternalMessageSender(IHttpClientFactory httpClientFactory, IOptions<NotificationChannelsOptions> options)
    {
        _httpClientFactory = httpClientFactory;
        _options = options;
    }

    public async Task<bool> SendWhatsAppAsync(string to, string message, CancellationToken cancellationToken = default)
    {
        var opt = _options.Value.WhatsApp;
        if (!opt.Enabled || string.IsNullOrWhiteSpace(opt.AccountSid) || string.IsNullOrWhiteSpace(opt.AuthToken) || string.IsNullOrWhiteSpace(opt.From))
        {
            return false;
        }

        var target = NormalizePhone(to);
        if (string.IsNullOrWhiteSpace(target))
        {
            return false;
        }

        var data = new Dictionary<string, string>
        {
            ["From"] = opt.From.StartsWith("whatsapp:", StringComparison.OrdinalIgnoreCase) ? opt.From : $"whatsapp:{opt.From}",
            ["To"] = target.StartsWith("whatsapp:", StringComparison.OrdinalIgnoreCase) ? target : $"whatsapp:{target}",
            ["Body"] = message
        };

        return await SendTwilioFormAsync(opt.AccountSid, opt.AuthToken, data, cancellationToken);
    }

    public async Task<bool> SendSmsAsync(string to, string message, CancellationToken cancellationToken = default)
    {
        var opt = _options.Value.Sms;
        if (!opt.Enabled || string.IsNullOrWhiteSpace(opt.AccountSid) || string.IsNullOrWhiteSpace(opt.AuthToken) || string.IsNullOrWhiteSpace(opt.From))
        {
            return false;
        }

        var target = NormalizePhone(to);
        if (string.IsNullOrWhiteSpace(target))
        {
            return false;
        }

        var data = new Dictionary<string, string>
        {
            ["From"] = opt.From,
            ["To"] = target,
            ["Body"] = message
        };

        return await SendTwilioFormAsync(opt.AccountSid, opt.AuthToken, data, cancellationToken);
    }

    private async Task<bool> SendTwilioFormAsync(string accountSid, string authToken, Dictionary<string, string> fields, CancellationToken cancellationToken)
    {
        try
        {
            var client = _httpClientFactory.CreateClient(nameof(TwilioExternalMessageSender));
            var auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{accountSid}:{authToken}"));
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", auth);

            var url = $"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json";
            using var content = new FormUrlEncodedContent(fields);
            using var response = await client.PostAsync(url, content, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                Log.Warning("Twilio send failed: {StatusCode} - {Body}", response.StatusCode, body);
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Twilio send failed with exception");
            return false;
        }
    }

    private static string NormalizePhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
        {
            return string.Empty;
        }

        var raw = phone.Trim();
        if (raw.StartsWith("+", StringComparison.Ordinal))
        {
            return raw;
        }

        return $"+{raw}";
    }
}
