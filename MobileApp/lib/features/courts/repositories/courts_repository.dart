import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/courts/models/court.dart';

class CourtsRepository {

  CourtsRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<CourtModel>> getCourts({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/courts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },);

    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(
            (raw) => CourtModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }

  Future<CourtModel?> getCourtById(String courtId) async {
    final response = await apiClient.get('/api/courts/$courtId');
    if (response.data == null) return null;
    return CourtModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CourtModel> createCourt(CourtModel court) async {
    final response = await apiClient.post('/api/courts', data: court.toJson());
    return CourtModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<CourtModel> updateCourt(CourtModel court) async {
    final response = await apiClient.put('/api/courts/${court.courtId}',
        data: court.toJson(),);
    return CourtModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCourt(String courtId) async {
    await apiClient.delete('/api/courts/$courtId');
  }

  Future<List<CourtModel>> searchCourts(String query) async {
    final response = await apiClient
        .get('/api/courts/search', queryParameters: {'q': query});
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
            (raw) => CourtModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }
}
