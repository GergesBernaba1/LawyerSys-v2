import 'package:dio/dio.dart';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/client-portal/models/portal_message.dart';

class ClientPortalRepository {

  ClientPortalRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<PortalMessageModel>> getMessages(
      {int page = 1, int pageSize = 50,}) async {
    final response =
        await apiClient.get('/api/clientportal/messages', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },);
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }

  Future<void> markMessageAsRead(String messageId) async {
    await apiClient.put('/api/clientportal/messages/$messageId/read');
  }

  Future<List<PortalMessageModel>> getDocuments(
      {int page = 1, int pageSize = 50,}) async {
    final response =
        await apiClient.get('/api/clientportal/documents', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },);
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            PortalMessageModel.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }

  Future<String?> getDocumentDownloadUrl(String messageId) async {
    try {
      final response =
          await apiClient.get('/api/clientportal/documents/$messageId/url');
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
    await apiClient.post('/api/clientportal/messages', data: {
      'subject': subject,
      'body': body,
    },);
  }

  Future<Map<String, dynamic>> getOverview() async {
    final response = await apiClient.get('/api/clientportal/overview');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return const {};
  }

  Future<void> uploadPortalDocument(String filePath, {String? title}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      if (title != null && title.isNotEmpty) 'title': title,
    });
    await apiClient.post('/api/clientportal/documents/upload', data: formData);
  }
}
