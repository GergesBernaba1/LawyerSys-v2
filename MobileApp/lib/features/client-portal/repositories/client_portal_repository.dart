import '../../core/api/api_client.dart';
import '../models/portal_message.dart';

class ClientPortalRepository {
  final ApiClient apiClient;

  ClientPortalRepository(this.apiClient);

  Future<List<PortalMessageModel>> getMessages({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/client-portal/messages', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((raw) => PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<void> markMessageAsRead(String messageId) async {
    await apiClient.put('/api/client-portal/messages/$messageId/read');
  }

  Future<List<PortalMessageModel>> getDocuments({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/client-portal/documents', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((raw) => PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }
