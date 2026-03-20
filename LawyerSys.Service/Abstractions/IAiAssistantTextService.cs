namespace LawyerSys.Services.AIAssistant;

public interface IAiAssistantTextService
{
    Task<string?> TryGenerateAsync(string systemPrompt, string userPrompt, CancellationToken cancellationToken = default);
}
