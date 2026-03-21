import '../../../core/api/api_client.dart';
import '../models/government.dart';

class GovernmentsRepository {
  final ApiClient apiClient;

  GovernmentsRepository(this.apiClient);

  Future<List<Government>> getGovernments() async {
    final response = await apiClient.get('/api/governorates');
    final items = (response.data as Map<String, dynamic>?)?['items'] as List<dynamic>?;
    if (items == null) return [];
    return items
        .map((e) => Government.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
