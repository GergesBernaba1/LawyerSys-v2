import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/json_utils.dart';
import '../models/calendar_event.dart';

class CalendarRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  CalendarRepository(this.apiClient, [LocalDatabase? db])
      : localDatabase = db ?? LocalDatabase.instance;

  Future<List<CalendarEvent>> getEvents({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await apiClient.get('/Calendar/events', queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
      });

      final eventsData = normalizeJsonList(response.data);
      final events = eventsData
          .whereType<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList();

      // Cache each event locally
      for (final event in events) {
        await localDatabase.upsertCalendarEvent(
          event.id,
          event.toJson(),
          fromDate: fromDate,
          toDate: toDate,
        );
      }

      return events;
    } catch (_) {
      // Offline fallback: return cached events in the requested range
      final rows = await localDatabase.getCalendarEvents(
        fromDate: fromDate,
        toDate: toDate,
      );
      return rows
          .map((row) => CalendarEvent.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<CalendarEvent> createEvent(Map<String, dynamic> data) async {
    final response = await apiClient.post('/Calendar/events', data: data);
    final created = CalendarEvent.fromJson(
        Map<String, dynamic>.from(response.data as Map));
    await localDatabase.upsertCalendarEvent(created.id, created.toJson());
    return created;
  }

  Future<CalendarEvent> updateEvent(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/Calendar/events/$id', data: data);
    final updated = CalendarEvent.fromJson(
        Map<String, dynamic>.from(response.data as Map));
    await localDatabase.upsertCalendarEvent(updated.id, updated.toJson());
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    await apiClient.delete('/Calendar/events/$id');
    // Remove from local cache
    final db = await localDatabase.database;
    await db.delete('calendar_events', where: 'eventId = ?', whereArgs: [id]);
  }
}
