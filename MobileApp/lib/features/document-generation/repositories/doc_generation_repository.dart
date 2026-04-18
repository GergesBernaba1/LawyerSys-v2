import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/doc_gen_models.dart';

class DocGenerationRepository {
  final ApiClient apiClient;

  DocGenerationRepository(this.apiClient);

  Future<List<DocTemplate>> getTemplates({String? language}) async {
    final response = await apiClient.get(
      '/documentgeneration/templates',
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(DocTemplate.fromJson)
        .toList();
  }

  Future<GeneratedDoc> generateDocument({
    required String templateId,
    required Map<String, dynamic> fieldValues,
    String? language,
    String? caseCode,
  }) async {
    final response = await apiClient.post(
      '/documentgeneration/generate',
      data: {
        'templateId': templateId,
        'fieldValues': fieldValues,
        if (language != null) 'language': language,
        if (caseCode != null) 'caseCode': caseCode,
      },
    );
    return GeneratedDoc.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GeneratedDoc>> getHistory({String? caseCode, int limit = 20}) async {
    final response = await apiClient.get(
      '/documentgeneration/history',
      queryParameters: {
        if (caseCode != null) 'caseCode': caseCode,
        'limit': limit,
      },
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(GeneratedDoc.fromJson)
        .toList();
  }

  Future<List<DocDraft>> getDrafts() async {
    final response = await apiClient.get('/documentgeneration/drafts');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(DocDraft.fromJson)
        .toList();
  }

  Future<DocDraft> createDraft({
    required String title,
    required String content,
    String? templateId,
  }) async {
    final response = await apiClient.post(
      '/documentgeneration/drafts',
      data: {
        'title': title,
        'content': content,
        if (templateId != null) 'templateId': templateId,
      },
    );
    return DocDraft.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDraft(String id) async {
    await apiClient.delete('/documentgeneration/drafts/$id');
  }
}
