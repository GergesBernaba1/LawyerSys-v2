import '../../../core/api/api_client.dart';
import '../models/case_relation.dart';

class CaseRelationsRepository {
  final ApiClient apiClient;

  CaseRelationsRepository(this.apiClient);

  Future<CaseRelations> getCaseRelations(int caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/full');
    return CaseRelations.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
