import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';

class ContendersRepository {
  ContendersRepository(this.apiClient);
  final ApiClient apiClient;

  static const int defaultPageSize = 50;

  Future<List<ContenderModel>> getContenders({
    int page = 1,
    int pageSize = defaultPageSize,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await apiClient.get('/api/contenders', queryParameters: params);
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => ContenderModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<ContenderModel?> getContenderById(String contenderId) async {
    final response = await apiClient.get('/api/contenders/$contenderId');
    if (response.data == null) return null;
    return ContenderModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ContenderModel> createContender(ContenderModel contender) async {
    final response = await apiClient.post('/api/contenders', data: contender.toJson());
    return ContenderModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ContenderModel> updateContender(ContenderModel contender) async {
    final response = await apiClient.put(
      '/api/contenders/${contender.contenderId}',
      data: contender.toJson(),
    );
    return ContenderModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteContender(String contenderId) async {
    await apiClient.delete('/api/contenders/$contenderId');
  }
}
