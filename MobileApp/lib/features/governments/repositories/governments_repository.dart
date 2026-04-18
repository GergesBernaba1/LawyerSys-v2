import '../../../core/api/api_client.dart';
import '../models/government.dart';

class GovernmentsRepository {
  final ApiClient apiClient;

  GovernmentsRepository(this.apiClient);

  Future<List<Government>> getGovernments() async {
    final response = await apiClient.get('/api/Governments');
    final data = response.data;

    List<dynamic>? items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = data['items'] as List<dynamic>?;
    }

    if (items == null) return [];
    return items
        .map((e) => Government.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
