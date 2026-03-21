import '../../core/api/api_client.dart';
import '../consultations/models/consultation.dart';

class ConsultationsRepository {
  final ApiClient apiClient;

  ConsultationsRepository(this.apiClient);

  Future<List<ConsultationModel>> getConsultations({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.get('/api/consultations', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((e) => ConsultationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<ConsultationModel?> getConsultationById(int id) async {
    final response = await apiClient.get('/api/consultations/$id');
    if (response.data == null) return null;
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ConsultationModel> createConsultation(ConsultationModel consultation) async {
    final response = await apiClient.post('/api/consultations', data: consultation.toJson());
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ConsultationModel> updateConsultation(ConsultationModel consultation) async {
    final response = await apiClient.put('/api/consultations/${consultation.id}', data: consultation.toJson());
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteConsultation(int id) async {
    await apiClient.delete('/api/consultations/$id');
  }

  Future<List<ConsultationModel>> searchConsultations(String query) async {
    final response = await apiClient.get('/api/consultations/search', queryParameters: {'q': query});
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((e) => ConsultationModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
