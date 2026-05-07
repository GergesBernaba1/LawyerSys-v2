import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/models/ai_models.dart';

class AiAssistantRepository {

  AiAssistantRepository(this.apiClient);
  final ApiClient apiClient;

  Future<AiSummaryResult> summarize(String text, {String? language}) async {
    final request = AiSummaryRequest(text: text, language: language);
    final response = await apiClient.post(
      '/aiassistant/summarize',
      data: request.toJson(),
    );
    return AiSummaryResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AiDraftResult> draft(
    String prompt, {
    String? documentType,
    String? language,
  }) async {
    final request = AiDraftRequest(
      prompt: prompt,
      documentType: documentType,
      language: language,
    );
    final response = await apiClient.post(
      '/aiassistant/draft',
      data: request.toJson(),
    );
    return AiDraftResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<AiDeadlineSuggestion>> getDeadlineSuggestions() async {
    final response =
        await apiClient.get('/aiassistant/task-deadline-suggestions');
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) =>
              AiDeadlineSuggestion.fromJson(Map<String, dynamic>.from(e)),)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map((e) =>
                AiDeadlineSuggestion.fromJson(Map<String, dynamic>.from(e)),)
            .toList();
      }
    }
    return const [];
  }
}
