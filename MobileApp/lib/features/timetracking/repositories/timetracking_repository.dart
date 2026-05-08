import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/timetracking/models/time_entry.dart';

class TimeTrackingRepository {

  TimeTrackingRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<TimeEntry>> getTimeEntries({
    String? statusFilter,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (statusFilter != null && statusFilter != 'All') {
      queryParameters['status'] = statusFilter;
    }

    final response =
        await apiClient.get('/TimeTracking', queryParameters: queryParameters);
    final entriesData = normalizeJsonList(response.data);
    return entriesData
        .whereType<Map<String, dynamic>>()
        .map(TimeEntry.fromJson)
        .toList();
  }

  Future<List<Suggestion>> getSuggestions({
    required double hourlyRate,
  }) async {
    final response =
        await apiClient.get('/TimeTracking/suggestions', queryParameters: {
      'hourlyRate': hourlyRate,
    },);
    final suggestionsData = normalizeJsonList(response.data);
    return suggestionsData
        .whereType<Map<String, dynamic>>()
        .map(Suggestion.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCaseOptions() async {
    // This would typically come from a cases endpoint
    // For now, we'll return an empty list and handle it in the UI
    // In a real implementation, this would call /Cases endpoint
    return [];
  }

  Future<void> startTimeEntry({
    int? caseCode,
    required String workType,
    String? description,
  }) async {
    await apiClient.post('/TimeTracking/start', data: {
      'caseCode': caseCode,
      'customerId': null, // Based on ClientApp code
      'workType': workType,
      'description': description,
    },);
  }

  Future<void> stopTimeEntry({
    required int entryId,
    double? hourlyRate,
  }) async {
    await apiClient.post('/TimeTracking/$entryId/stop', data: {
      'hourlyRate': hourlyRate,
    },);
  }

  Future<void> deleteTimeEntry(int entryId) async {
    await apiClient.delete('/TimeTracking/$entryId');
  }
}
