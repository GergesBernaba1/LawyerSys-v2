import '../../../core/api/api_client.dart';
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

    final eventsData = response.data as List<dynamic>? ?? [];
    return eventsData.map((json) => CalendarEvent.fromJson(json)).toList();
  }
}