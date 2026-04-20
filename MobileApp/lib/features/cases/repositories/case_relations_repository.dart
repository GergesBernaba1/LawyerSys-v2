import '../../../core/api/api_client.dart';
import '../models/case_relation.dart';

class CaseRelationsRepository {
  final ApiClient apiClient;
  CaseRelationsRepository(this.apiClient);

  Future<List<CaseRelation>> getRelations(int caseId) async {
    final response = await apiClient.get('/CaseRelations', queryParameters: {'caseId': caseId});
    final data = response.data;
    final list = data is List ? data : (data is Map ? (data['items'] ?? data['data'] ?? []) : []);
    return (list as List)
        .whereType<Map>()
        .map((e) => CaseRelation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createRelation(
    int caseId,
    int relatedCaseId,
    String relationType, {
    String? notes,
  }) async {
    await apiClient.post('/CaseRelations', data: {
      'caseId': caseId,
      'relatedCaseId': relatedCaseId,
      'relationType': relationType,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> deleteRelation(int id) async {
    await apiClient.delete('/CaseRelations/$id');
  }
}
