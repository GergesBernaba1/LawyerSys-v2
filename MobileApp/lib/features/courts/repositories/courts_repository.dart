import '../../core/api/api_client.dart';
import '../courts/models/court.dart';

class CourtsRepository {
  final ApiClient apiClient;

  CourtsRepository(this.apiClient);

  Future<List<CourtModel>> getCourts({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/courts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    final data = response.data as List<dynamic>?;
    if (data == null) return [];

    return data.map((raw) => CourtModel.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
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
    final response = await apiClient.put('/api/courts/${court.courtId}', data: court.toJson());
    return CourtModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCourt(String courtId) async {
    await apiClient.delete('/api/courts/$courtId');
  }

  Future<List<CourtModel>> searchCourts(String query) async {
    final response = await apiClient.get('/api/courts/search', queryParameters: {'q': query});
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((raw) => CourtModel.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }
}
