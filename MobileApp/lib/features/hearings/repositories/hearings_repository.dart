import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/utils/json_utils.dart';
import '../models/hearing.dart';

class HearingsRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  HearingsRepository(this.apiClient, this.localDatabase);

  Future<List<Hearing>> getHearings(
      {String? tenantId,
      int page = 1,
      int pageSize = 50,
      DateTime? startDate,
      DateTime? endDate}) async {
    try {
      final queryParams = {
        'page': page,
        'pageSize': pageSize,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };
      final response =
          await apiClient.get('/api/sitings', queryParameters: queryParams);
      final data = normalizeJsonList(response.data);
      final items = data
          .whereType<Map<String, dynamic>>()
          .map((raw) => Hearing.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList();

      for (final hearing in items) {
        await localDatabase.upsertHearing(hearing.hearingId, hearing.toJson(),
            tenantId: hearing.tenantId, isDirty: false);
      }

      return items;
    } catch (_) {
      final cached = await localDatabase.getHearings(
          tenantId: tenantId, limit: pageSize, offset: (page - 1) * pageSize);
      return cached
          .map((row) => Hearing.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<Hearing?> getHearingById(String hearingId) async {
    try {
      final response = await apiClient.get('/api/sitings/$hearingId');
      if (response.data == null) return null;
      final hearing =
          Hearing.fromJson(Map<String, dynamic>.from(response.data));
      await localDatabase.upsertHearing(hearing.hearingId, hearing.toJson(),
          tenantId: hearing.tenantId, isDirty: false);
      return hearing;
    } catch (_) {
      final cached = await localDatabase.getHearings();
      return cached
          .map((row) => Hearing.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .firstWhere((e) => e.hearingId == hearingId,
              orElse: () => throw StateError('Hearing not found'));
    }
  }

  Future<void> createHearing(Hearing hearing) async {
    try {
      final response =
          await apiClient.post('/api/sitings', data: hearing.toJson());
      final created =
          Hearing.fromJson(Map<String, dynamic>.from(response.data));
      await localDatabase.upsertHearing(created.hearingId, created.toJson(),
          tenantId: created.tenantId, isDirty: false);
    } catch (_) {
      await localDatabase.upsertHearing(hearing.hearingId, hearing.toJson(),
          tenantId: hearing.tenantId, isDirty: true);
      rethrow;
    }
  }

  Future<void> updateHearing(Hearing hearing) async {
    try {
      await apiClient.put('/api/sitings/${hearing.hearingId}',
          data: hearing.toJson());
      await localDatabase.upsertHearing(hearing.hearingId, hearing.toJson(),
          tenantId: hearing.tenantId, isDirty: false);
    } catch (_) {
      await localDatabase.upsertHearing(hearing.hearingId, hearing.toJson(),
          tenantId: hearing.tenantId, isDirty: true);
      rethrow;
    }
  }

  Future<void> deleteHearing(String hearingId) async {
    try {
      await apiClient.delete('/api/sitings/$hearingId');
      await localDatabase.deleteHearing(hearingId);
    } catch (_) {
      await localDatabase.deleteHearing(hearingId);
      rethrow;
    }
  }

  Future<List<Hearing>> searchHearings(String query, {String? tenantId}) async {
    try {
      final response = await apiClient
          .get('/api/sitings/search', queryParameters: {'q': query});
      final data = normalizeJsonList(response.data);
      return data
          .whereType<Map<String, dynamic>>()
          .map((raw) => Hearing.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList();
    } catch (_) {
      final cached =
          await localDatabase.getHearings(tenantId: tenantId, limit: 200);
      return cached
          .map((row) => Hearing.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .where((h) =>
              h.caseNumber.toLowerCase().contains(query.toLowerCase()) ||
              h.judgeName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
