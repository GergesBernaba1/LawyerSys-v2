using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LawyerSys.Services.Notifications;

public class FirebasePushNotificationService : IPushNotificationService
{
    private readonly FirebaseOptions _options;
    private readonly ILogger<FirebasePushNotificationService> _logger;
    private readonly object _appLock = new object();

    public FirebasePushNotificationService(IOptions<FirebaseOptions> options, ILogger<FirebasePushNotificationService> logger)
    {
        _options = options?.Value ?? new FirebaseOptions();
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task SendAsync(
        IEnumerable<string> deviceTokens,
        string title,
        string body,
        string? route = null,
        IDictionary<string, string>? data = null,
        CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            return;
        }

        var tokens = deviceTokens
            .Where(token => !string.IsNullOrWhiteSpace(token))
            .Distinct(StringComparer.Ordinal)
            .ToList();

        if (tokens.Count == 0)
        {
            return;
        }

        try
        {
            EnsureFirebaseAppInitialized();

            if (FirebaseApp.DefaultInstance == null)
            {
                _logger.LogWarning("FirebaseApp not initialized; cannot send push notifications.");
                return;
            }

            var payloadData = data?.ToDictionary(kvp => kvp.Key, kvp => kvp.Value)
                ?? new Dictionary<string, string>(StringComparer.Ordinal);

            if (!string.IsNullOrWhiteSpace(route))
            {
                payloadData["route"] = route;
            }

            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = payloadData,
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        Title = title,
                        Body = body,
                        ClickAction = route
                    }
                },
                Apns = new ApnsConfig
                {
                    FcmOptions = new ApnsFcmOptions
                    {
                        AnalyticsLabel = "qadaya"
                    },
                    Aps = new Aps
                    {
                        Alert = new ApsAlert
                        {
                            Title = title,
                            Body = body
                        },
                        Sound = "default"
                    }
                }
            };
            var response = await FirebaseMessaging.GetMessaging(FirebaseApp.DefaultInstance)
                .SendEachForMulticastAsync(message, cancellationToken);

            if (response.FailureCount > 0)
            {
                foreach (var (token, resp) in tokens.Zip(response.Responses, (token, resp) => (token, resp)))
                {
                    if (!resp.IsSuccess)
                    {
                        _logger.LogWarning("Failed to send FCM message to token {Token}: {Error}", token, resp.Exception?.Message);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending Firebase push notification");
        }
    }

    private void EnsureFirebaseAppInitialized()
    {
        if (!string.IsNullOrWhiteSpace(_options.ServiceAccountKeyPath) && FirebaseApp.DefaultInstance == null)
        {
            lock (_appLock)
            {
                if (FirebaseApp.DefaultInstance != null)
                {
                    return;
                }

                var credentials = GoogleCredential.FromFile(_options.ServiceAccountKeyPath);
                var appOptions = new AppOptions
                {
                    Credential = credentials,
                    ProjectId = _options.ProjectId,
                };

                FirebaseApp.Create(appOptions);
                _logger.LogInformation("Firebase app initialized using service account key from {Path}", _options.ServiceAccountKeyPath);
            }
        }
    }
}
