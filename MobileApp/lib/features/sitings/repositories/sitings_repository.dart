import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/sitings/models/siting_model.dart';

class SitingsRepository {

  SitingsRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<List<SitingModel>> getSitings({
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await apiClient.get('/sitings', queryParameters: queryParams);
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => SitingModel.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<SitingModel> getSitingById(int id) async {
    final response = await apiClient.get('/sitings/$id');
    return SitingModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<SitingModel> createSiting(Map<String, dynamic> data) async {
    final response = await apiClient.post('/sitings', data: data);
    return SitingModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<SitingModel> updateSiting(int id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/sitings/$id', data: data);
    return SitingModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteSiting(int id) async {
    await apiClient.delete('/sitings/$id');
  }
}
