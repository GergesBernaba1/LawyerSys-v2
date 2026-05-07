import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';

class ContendersRepository {

  ContendersRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<ContenderModel>> getContenders(
      {int page = 1, int pageSize = 50,}) async {
    final response = await apiClient.get('/api/contenders', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },);

    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            ContenderModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }

  Future<ContenderModel?> getContenderById(String contenderId) async {
    final response = await apiClient.get('/api/contenders/$contenderId');
    if (response.data == null) return null;
    return ContenderModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<ContenderModel> createContender(ContenderModel contender) async {
    final response =
        await apiClient.post('/api/contenders', data: contender.toJson());
    return ContenderModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<ContenderModel> updateContender(ContenderModel contender) async {
    final response = await apiClient.put(
        '/api/contenders/${contender.contenderId}',
        data: contender.toJson(),);
    return ContenderModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<void> deleteContender(String contenderId) async {
    await apiClient.delete('/api/contenders/$contenderId');
  }

  Future<List<ContenderModel>> searchContenders(String query) async {
    final response = await apiClient
        .get('/api/contenders/search', queryParameters: {'q': query});
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            ContenderModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }
}
