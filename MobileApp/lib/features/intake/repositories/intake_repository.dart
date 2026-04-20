import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/intake_form.dart';

class IntakeRepository {
  final ApiClient apiClient;

  IntakeRepository(this.apiClient);

  Future<List<IntakeForm>> getLeads({String? status, String? search}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response =
        await apiClient.get('/api/Intake', queryParameters: params);
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => IntakeForm.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<IntakeForm> getById(int id) async {
    final response = await apiClient.get('/api/Intake/$id');
    return IntakeForm.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<IntakeForm> createPublicLead(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/Intake/public', data: payload);
    return IntakeForm.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<IntakeAssignmentOption>> getAssignmentOptions() async {
    final response = await apiClient.get('/api/Intake/assignment-options');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => IntakeAssignmentOption.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<IntakeConflictCheck> runConflictCheck(int id) async {
    final response = await apiClient.get('/api/Intake/$id/conflict-check');
    return IntakeConflictCheck.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<IntakeForm> qualify(int id,
      {required bool isQualified, String? notes}) async {
    final response = await apiClient.post('/api/Intake/$id/qualify',
        data: {'isQualified': isQualified, 'notes': notes});
    return IntakeForm.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<IntakeForm> assign(int id,
      {required int assignedEmployeeId, DateTime? nextFollowUpAt}) async {
    final response = await apiClient.post('/api/Intake/$id/assign', data: {
      'assignedEmployeeId': assignedEmployeeId,
      'nextFollowUpAt': nextFollowUpAt?.toIso8601String(),
    });
    return IntakeForm.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Map<String, dynamic>> convert(int id,
      {String? caseType, int? initialAmount}) async {
    final response = await apiClient.post('/api/Intake/$id/convert', data: {
      'caseType': caseType,
      'initialAmount': initialAmount ?? 0,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<String?> getPublicIntakeLink() async {
    try {
      final response = await apiClient.get('/intake/public-link');
      if (response.data is Map) {
        return (response.data as Map)['url']?.toString()
            ?? (response.data as Map)['link']?.toString()
            ?? (response.data as Map)['publicUrl']?.toString();
      }
      return response.data?.toString();
    } catch (_) {
      return null;
    }
  }
}
