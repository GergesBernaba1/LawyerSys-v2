import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/calendar_event.dart';

class CalendarRepository {
  final ApiClient apiClient;

  CalendarRepository(this.apiClient);

  Future<List<CalendarEvent>> getEvents({
    required String fromDate,
    required String toDate,
  }) async {
    final response = await apiClient.get('/Calendar/events', queryParameters: {
      'fromDate': fromDate,
      'toDate': toDate,
    });

    final eventsData = normalizeJsonList(response.data);
    return eventsData
        .whereType<Map<String, dynamic>>()
        .map(CalendarEvent.fromJson)
        .toList();
  }

  Future<CalendarEvent> createEvent(Map<String, dynamic> data) async {
    final response = await apiClient.post('/Calendar/events', data: data);
    return CalendarEvent.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<CalendarEvent> updateEvent(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/Calendar/events/$id', data: data);
    return CalendarEvent.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteEvent(String id) async {
    await apiClient.delete('/Calendar/events/$id');
  }
}
