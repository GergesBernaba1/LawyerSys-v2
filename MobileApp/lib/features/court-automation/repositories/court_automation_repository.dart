import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/court-automation/models/court_automation_models.dart';

class CourtAutomationRepository {

  CourtAutomationRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<AutomationPack>> getPacks({String? language}) async {
    final response = await apiClient.get(
      '/courtautomation/packs',
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(AutomationPack.fromJson)
        .toList();
  }

  Future<List<DeadlineItem>> calculateDeadlines({
    required String packKey,
    required String filingDate,
  }) async {
    final response = await apiClient.post(
      '/courtautomation/calculate-deadlines',
      data: {
        'packKey': packKey,
        'filingDate': filingDate,
      },
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(DeadlineItem.fromJson)
        .toList();
  }

  Future<FilingSubmission> submitFiling({
    required String caseCode,
    required String packKey,
    required Map<String, dynamic> formData,
  }) async {
    final response = await apiClient.post(
      '/courtautomation/filings/submit',
      data: {
        'caseCode': caseCode,
        'packKey': packKey,
        'formData': formData,
      },
    );
    return FilingSubmission.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FilingSubmission>> getFilings({
    String? caseCode,
    String? packKey,
  }) async {
    final response = await apiClient.get(
      '/courtautomation/filings',
      queryParameters: {
        if (caseCode != null) 'caseCode': caseCode,
        if (packKey != null) 'packKey': packKey,
      },
    );
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(FilingSubmission.fromJson)
        .toList();
  }
}
