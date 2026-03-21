import '../../../core/api/api_client.dart';
import '../models/judicial_document.dart';

class JudicialDocumentsRepository {
  final ApiClient apiClient;

  JudicialDocumentsRepository(this.apiClient);

  Future<({List<JudicialDocument> items, int totalCount})> getDocuments({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await apiClient.get('/api/JudicialDocuments', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => JudicialDocument.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (items: items, totalCount: data['totalCount'] as int? ?? items.length);
  }

  Future<JudicialDocument?> getById(int id) async {
    final response = await apiClient.get('/api/JudicialDocuments/$id');
    if (response.data == null) return null;
    return JudicialDocument.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<JudicialDocument> create(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/JudicialDocuments', data: payload);
    return JudicialDocument.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<JudicialDocument> update(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/JudicialDocuments/$id', data: payload);
    return JudicialDocument.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> delete(int id) async {
    await apiClient.delete('/api/JudicialDocuments/$id');
  }
}
