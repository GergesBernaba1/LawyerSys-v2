import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/governments/models/government.dart';

class GovernmentsRepository {

  GovernmentsRepository(this.apiClient);
  final ApiClient apiClient;

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

  Future<Government> createGovernment(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/Governments', data: data);
    return Government.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Government> updateGovernment(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/api/Governments/$id', data: data);
    return Government.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteGovernment(String id) async {
    await apiClient.delete('/api/Governments/$id');
  }
}
