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

        try
        {
            var client = _httpClientFactory.CreateClient(nameof(AiAssistantTextService));
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", opt.ApiKey);

            var requestBody = new
            {
                model = string.IsNullOrWhiteSpace(opt.Model) ? "gpt-4.1-mini" : opt.Model,
                temperature = Math.Clamp(opt.Temperature, 0, 2),
                max_output_tokens = Math.Clamp(opt.MaxOutputTokens, 128, 4096),
                input = new object[]
                {
                    new
                    {
                        role = "system",
                        content = new object[]
                        {
                            new { type = "input_text", text = systemPrompt }
                        }
                    },
                    new
                    {
                        role = "user",
                        content = new object[]
                        {
                            new { type = "input_text", text = userPrompt }
                        }
                    }
                }
            };

            var url = $"{opt.BaseUrl.TrimEnd('/')}/responses";
            using var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
            using var response = await client.PostAsync(url, content, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogWarning("AI request failed: {StatusCode} {Body}", response.StatusCode, body);
                return null;
            }

            var raw = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(raw);
            return ExtractText(doc.RootElement);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AI request failed with exception");
            return null;
        }
    }

    private static string? ExtractText(JsonElement root)
    {
        if (root.TryGetProperty("output_text", out var outputText))
        {
            if (outputText.ValueKind == JsonValueKind.String)
            {
                var text = outputText.GetString();
                return string.IsNullOrWhiteSpace(text) ? null : text.Trim();
            }

            if (outputText.ValueKind == JsonValueKind.Array)
            {
                var merged = string.Join("\n", outputText.EnumerateArray()
                    .Where(x => x.ValueKind == JsonValueKind.String)
                    .Select(x => x.GetString())
                    .Where(x => !string.IsNullOrWhiteSpace(x)));
                if (!string.IsNullOrWhiteSpace(merged))
                {
                    return merged.Trim();
                }
            }
        }

        if (root.TryGetProperty("output", out var output) && output.ValueKind == JsonValueKind.Array)
        {
            var parts = new List<string>();
            foreach (var item in output.EnumerateArray())
            {
                if (!item.TryGetProperty("content", out var content) || content.ValueKind != JsonValueKind.Array)
                {
                    continue;
                }

                foreach (var segment in content.EnumerateArray())
                {
                    if (segment.TryGetProperty("text", out var textNode) && textNode.ValueKind == JsonValueKind.String)
                    {
                        var text = textNode.GetString();
                        if (!string.IsNullOrWhiteSpace(text))
                        {
                            parts.Add(text);
                        }
                    }
                }
            }

            if (parts.Count > 0)
            {
                return string.Join("\n", parts).Trim();
            }
        }

        return null;
    }
}
