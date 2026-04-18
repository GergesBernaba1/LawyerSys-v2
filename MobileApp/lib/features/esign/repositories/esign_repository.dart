import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/esign_request.dart';

class ESignRepository {
  final ApiClient apiClient;

  ESignRepository(this.apiClient);

  Future<List<ESignRequest>> getRequests({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await apiClient.get(
      '/esign',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ESignRequest.fromJson)
        .toList();
  }

  Future<ESignRequest> createRequest({
    required String title,
    required String documentContent,
    required List<String> signerEmails,
    DateTime? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'documentContent': documentContent,
      'signerEmails': signerEmails,
    };
    if (expiresAt != null) {
      body['expiresAt'] = expiresAt.toIso8601String();
    }

    final response = await apiClient.post('/esign/requests', data: body);
    return ESignRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, String status) async {
    await apiClient.post(
      '/esign/requests/$id/status',
      data: {'status': status},
    );
  }

  Future<String> getShareLink(String id) async {
    final response = await apiClient.post('/esign/requests/$id/share-link');
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
