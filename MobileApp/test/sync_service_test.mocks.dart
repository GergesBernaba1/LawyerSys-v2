// ignore_for_file: camel_case_types, non_constant_identifier_names
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member
// ignore_for_file: unnecessary_parenthesis

import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/core/sync/sync_queue_item.dart';

// ── MockApiClient ─────────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {
  @override
  Future<Response<dynamic>> get(String? path,
          {Map<String, dynamic>? queryParameters}) =>
      (super.noSuchMethod(
        Invocation.method(#get, [path], {#queryParameters: queryParameters}),
        returnValue: Future.value(_emptyResponse()),
        returnValueForMissingStub: Future.value(_emptyResponse()),
      ) as Future<Response<dynamic>>);

  @override
  Future<Response<dynamic>> post(String? path, {dynamic data}) =>
      (super.noSuchMethod(
        Invocation.method(#post, [path], {#data: data}),
        returnValue: Future.value(_emptyResponse()),
        returnValueForMissingStub: Future.value(_emptyResponse()),
      ) as Future<Response<dynamic>>);

  @override
  Future<Response<dynamic>> put(String? path, {dynamic data}) =>
      (super.noSuchMethod(
        Invocation.method(#put, [path], {#data: data}),
        returnValue: Future.value(_emptyResponse()),
        returnValueForMissingStub: Future.value(_emptyResponse()),
      ) as Future<Response<dynamic>>);

  @override
  Future<Response<dynamic>> delete(String? path, {dynamic data}) =>
      (super.noSuchMethod(
        Invocation.method(#delete, [path], {#data: data}),
        returnValue: Future.value(_emptyResponse()),
        returnValueForMissingStub: Future.value(_emptyResponse()),
      ) as Future<Response<dynamic>>);
}

// ── MockLocalDatabase ─────────────────────────────────────────────────────────

class MockLocalDatabase extends Mock implements LocalDatabase {
  @override
  Future<List<SyncQueueItem>> getSyncQueueItems() =>
      (super.noSuchMethod(
        Invocation.method(#getSyncQueueItems, []),
        returnValue: Future.value(<SyncQueueItem>[]),
        returnValueForMissingStub: Future.value(<SyncQueueItem>[]),
      ) as Future<List<SyncQueueItem>>);

  @override
  Future<void> removeSyncQueueItem(String? id) =>
      (super.noSuchMethod(
        Invocation.method(#removeSyncQueueItem, [id]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> updateSyncQueueRetryCount(String? id, int? retryCount) =>
      (super.noSuchMethod(
        Invocation.method(#updateSyncQueueRetryCount, [id, retryCount]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> addSyncActivity(String? id, String? queueId,
          String? entityType, String? operationType, String? status,
          String? message) =>
      (super.noSuchMethod(
        Invocation.method(
            #addSyncActivity, [id, queueId, entityType, operationType, status, message]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertSyncMetrics(String? metricId, DateTime? lastSyncAt,
          int? attempted, int? succeeded, int? failed, int? canceled) =>
      (super.noSuchMethod(
        Invocation.method(#upsertSyncMetrics,
            [metricId, lastSyncAt, attempted, succeeded, failed, canceled]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<Map<String, dynamic>?> getSyncMetrics(String? metricId) =>
      (super.noSuchMethod(
        Invocation.method(#getSyncMetrics, [metricId]),
        returnValue: Future.value(null),
        returnValueForMissingStub: Future.value(null),
      ) as Future<Map<String, dynamic>?>);

  @override
  Future<void> upsertCase(String? caseId, Map<String, dynamic>? caseJson,
          {String? tenantId, bool isDirty = false}) =>
      (super.noSuchMethod(
        Invocation.method(
            #upsertCase, [caseId, caseJson], {#tenantId: tenantId, #isDirty: isDirty}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> deleteCase(String? caseId) =>
      (super.noSuchMethod(
        Invocation.method(#deleteCase, [caseId]),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertHearing(String? hearingId, Map<String, dynamic>? hearingJson,
          {String? tenantId, bool isDirty = false}) =>
      (super.noSuchMethod(
        Invocation.method(#upsertHearing, [hearingId, hearingJson],
            {#tenantId: tenantId, #isDirty: isDirty}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertCustomer(String? customerId, Map<String, dynamic>? customerJson,
          {String? tenantId}) =>
      (super.noSuchMethod(
        Invocation.method(
            #upsertCustomer, [customerId, customerJson], {#tenantId: tenantId}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertDocument(String? documentId, Map<String, dynamic>? documentJson,
          {String? tenantId, bool isDownloaded = false}) =>
      (super.noSuchMethod(
        Invocation.method(#upsertDocument, [documentId, documentJson],
            {#tenantId: tenantId, #isDownloaded: isDownloaded}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertEmployee(String? employeeId, Map<String, dynamic>? employeeJson,
          {String? tenantId, bool isDirty = false}) =>
      (super.noSuchMethod(
        Invocation.method(#upsertEmployee, [employeeId, employeeJson],
            {#tenantId: tenantId, #isDirty: isDirty}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);

  @override
  Future<void> upsertDashboard(String? key, Map<String, dynamic>? summaryJson,
          {String? tenantId}) =>
      (super.noSuchMethod(
        Invocation.method(
            #upsertDashboard, [key, summaryJson], {#tenantId: tenantId}),
        returnValue: Future.value(),
        returnValueForMissingStub: Future.value(),
      ) as Future<void>);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Response<dynamic> _emptyResponse({dynamic data, int statusCode = 200}) =>
    Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

Response<dynamic> listResponse(List<dynamic> data) =>
    _emptyResponse(data: data);

Response<dynamic> mapResponse(Map<String, dynamic> data) =>
    _emptyResponse(data: data);

SyncQueueItem makeQueueItem({
  required String id,
  required String operationType,
  String entityType = 'case',
  String entityId = 'c1',
  Map<String, dynamic>? payload,
  int retryCount = 0,
}) =>
    SyncQueueItem(
      id: id,
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload ?? {'caseId': entityId, 'tenantId': 't1'},
      retryCount: retryCount,
    );
