import 'package:qadaya_lawyersys/core/api/api_client.dart';

class CaseConversationRepository {
  CaseConversationRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<Map<String, dynamic>>> getMessages(String caseCode) async {
    final response =
        await apiClient.get('/api/cases/$caseCode/conversation');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map
            ? (data['items'] ?? data['data'] ?? <dynamic>[])
            : <dynamic>[]);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage({
    required String caseCode,
    required String message,
    required bool visibleToCustomer,
  }) async {
    final response = await apiClient.post(
      '/api/cases/$caseCode/conversation',
      data: {
        'message': message,
        'visibleToCustomer': visibleToCustomer,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
