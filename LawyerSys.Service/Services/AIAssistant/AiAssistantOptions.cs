namespace LawyerSys.Services.AIAssistant;

public class AiAssistantOptions
{
    public bool Enabled { get; set; }
    public string Provider { get; set; } = "OpenAI";
    public string ApiKey { get; set; } = string.Empty;
    public string BaseUrl { get; set; } = "https://api.openai.com/v1";
    public string Model { get; set; } = "gpt-4o";
    public int MaxOutputTokens { get; set; } = 900;
    public double Temperature { get; set; } = 0.2;
}
