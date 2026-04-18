import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/portal_message.dart';

class ClientPortalRepository {
  final ApiClient apiClient;

  ClientPortalRepository(this.apiClient);

  Future<List<PortalMessageModel>> getMessages(
      {int page = 1, int pageSize = 50}) async {
    final response =
        await apiClient.get('/api/client-portal/messages', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<void> markMessageAsRead(String messageId) async {
    await apiClient.put('/api/client-portal/messages/$messageId/read');
  }

  Future<List<PortalMessageModel>> getDocuments(
      {int page = 1, int pageSize = 50}) async {
    final response =
        await apiClient.get('/api/client-portal/documents', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<String?> getDocumentDownloadUrl(String messageId) async {
    try {
      final response =
          await apiClient.get('/api/client-portal/documents/$messageId/url');
      if (response.data is Map) {
        return (response.data as Map)['url']?.toString() ??
            (response.data as Map)['downloadUrl']?.toString();
      }
      return response.data?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage(String subject, String body) async {
    await apiClient.post('/api/client-portal/messages', data: {
      'subject': subject,
      'body': body,
    });
  }
}
