using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LawyerSys.Services.AIAssistant;

public sealed class AiAssistantTextService : IAiAssistantTextService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IOptions<AiAssistantOptions> _options;
    private readonly ILogger<AiAssistantTextService> _logger;
    private static readonly SemaphoreSlim _rateLimiter = new(1, 1);
    private static DateTime _lastRequestTime = DateTime.MinValue;
    private static readonly TimeSpan _minimumRequestInterval = TimeSpan.FromSeconds(3); // Min 3 seconds between requests

    public AiAssistantTextService(
        IHttpClientFactory httpClientFactory,
        IOptions<AiAssistantOptions> options,
        ILogger<AiAssistantTextService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _options = options;
        _logger = logger;
    }

    public async Task<string?> TryGenerateAsync(string systemPrompt, string userPrompt, CancellationToken cancellationToken = default)
    {
        var opt = _options.Value;
        if (!opt.Enabled || string.IsNullOrWhiteSpace(opt.ApiKey))
        {
            return null;
        }

        if (!string.Equals(opt.Provider, "OpenAI", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning("Unsupported AI provider configured: {Provider}", opt.Provider);
            return null;
        }

        // Rate limiting: ensure minimum time between requests
        await _rateLimiter.WaitAsync(cancellationToken);
        try
        {
            var timeSinceLastRequest = DateTime.UtcNow - _lastRequestTime;
            if (timeSinceLastRequest < _minimumRequestInterval)
            {
                var delayNeeded = _minimumRequestInterval - timeSinceLastRequest;
                _logger.LogInformation("Rate limiting: waiting {Delay}ms before request", delayNeeded.TotalMilliseconds);
                await Task.Delay(delayNeeded, cancellationToken);
            }
            _lastRequestTime = DateTime.UtcNow;
        }
        finally
        {
            _rateLimiter.Release();
        }

        const int maxRetries = 3;
        var retryDelays = new[] { 5000, 15000, 30000 }; // 5s, 15s, 30s - more conservative for rate limits

        for (int attempt = 0; attempt <= maxRetries; attempt++)
        {
            try
            {
                var client = _httpClientFactory.CreateClient(nameof(AiAssistantTextService));
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", opt.ApiKey);

                var requestBody = new
                {
                    model = string.IsNullOrWhiteSpace(opt.Model) ? "gpt-4" : opt.Model,
                    temperature = Math.Clamp(opt.Temperature, 0, 2),
                    max_tokens = Math.Clamp(opt.MaxOutputTokens, 128, 4096),
                    messages = new object[]
                    {
                        new
                        {
                            role = "system",
                            content = systemPrompt
                        },
                        new
                        {
                            role = "user",
                            content = userPrompt
                        }
                    }
                };

                var url = $"{opt.BaseUrl.TrimEnd('/')}/chat/completions";
                using var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
                using var response = await client.PostAsync(url, content, cancellationToken);
                
                if (!response.IsSuccessStatusCode)
                {
                    var body = await response.Content.ReadAsStringAsync(cancellationToken);
                    
                    if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
                    {
                        var retryAfter = response.Headers.RetryAfter?.Delta?.TotalSeconds 
                            ?? response.Headers.RetryAfter?.Date?.Subtract(DateTimeOffset.UtcNow).TotalSeconds;
                        
                        _logger.LogWarning(
                            "AI rate limit exceeded (429) on attempt {Attempt}/{MaxRetries}. RetryAfter: {RetryAfter}s, Body: {Body}",
                            attempt + 1,
                            maxRetries + 1,
                            retryAfter,
                            body);

                        if (attempt < maxRetries)
                        {
                            var delayMs = retryAfter.HasValue 
                                ? (int)(retryAfter.Value * 1000) 
                                : retryDelays[attempt];
                            
                            _logger.LogInformation("Waiting {DelayMs}ms before retry", delayMs);
                            await Task.Delay(delayMs, cancellationToken);
                            continue;
                        }
                    }
                    else
                    {
                        _logger.LogWarning("AI request failed: {StatusCode} {ReasonPhrase} {Body}", 
                            response.StatusCode, response.ReasonPhrase, body);
                    }
                    
                    return null;
                }

                var raw = await response.Content.ReadAsStringAsync(cancellationToken);
                using var doc = JsonDocument.Parse(raw);
                return ExtractText(doc.RootElement);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "AI request failed with exception on attempt {Attempt}/{MaxRetries}", 
                    attempt + 1, maxRetries + 1);
                
                if (attempt >= maxRetries)
                {
                    return null;
                }
                
                await Task.Delay(retryDelays[attempt], cancellationToken);
            }
        }

        return null;
    }

    private static string? ExtractText(JsonElement root)
    {
        if (root.TryGetProperty("choices", out var choices) && choices.ValueKind == JsonValueKind.Array)
        {
            foreach (var choice in choices.EnumerateArray())
            {
                if (choice.TryGetProperty("message", out var message) &&
                    message.TryGetProperty("content", out var content) &&
                    content.ValueKind == JsonValueKind.String)
                {
                    var text = content.GetString();
                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        return text.Trim();
                    }
                }
            }
        }

        return null;
    }
}
