import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:qadaya_lawyersys/core/sync/sync_service.dart';

import 'sync_service_test.mocks.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

DioException _dioError(int statusCode) => DioException(
      requestOptions: RequestOptions(),
      response: Response(
        statusCode: statusCode,
        requestOptions: RequestOptions(),
      ),
      type: DioExceptionType.badResponse,
    );

DioException _networkError() => DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.connectionError,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockApiClient mockApi;
  late MockLocalDatabase mockDb;
  late SyncService sut;

  setUp(() {
    mockApi = MockApiClient();
    mockDb = MockLocalDatabase();
    sut = SyncService(apiClient: mockApi, localDatabase: mockDb);

    // Default stubs that every test needs
    when(mockDb.upsertSyncMetrics(any, any, any, any, any, any))
        .thenAnswer((_) async {});
    when(mockDb.addSyncActivity(any, any, any, any, any, any))
        .thenAnswer((_) async {});
    when(mockDb.removeSyncQueueItem(any)).thenAnswer((_) async {});
    when(mockDb.updateSyncQueueRetryCount(any, any)).thenAnswer((_) async {});
  });

  // ── syncPendingOperations — empty queue ──────────────────────────────────────

  group('syncPendingOperations — empty queue', () {
    test('does nothing and persists zero metrics', () async {
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => []);

      await sut.syncPendingOperations();

      verifyNever(mockApi.post(any));
      verifyNever(mockApi.put(any));
      verifyNever(mockApi.delete(any));
      verify(mockDb.upsertSyncMetrics(any, any, 0, 0, 0, 0)).called(1);
    });
  });

  // ── create_case ──────────────────────────────────────────────────────────────

  group('create_case', () {
    test('posts to /api/cases, upserts response, removes from queue', () async {
      final item = makeQueueItem(id: 'q1', operationType: 'create_case');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.post('/api/cases', data: anyNamed('data'))).thenAnswer(
          (_) async => mapResponse({'caseId': 'c1', 'tenantId': 't1'}),);
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});

      await sut.syncPendingOperations();

      verify(mockApi.post('/api/cases', data: anyNamed('data'))).called(1);
      verify(mockDb.upsertCase('c1', any,
              tenantId: 't1',),)
          .called(1);
      verify(mockDb.removeSyncQueueItem('q1')).called(1);
      verify(mockDb.addSyncActivity('q1', 'q1', 'case', 'create_case',
              'success', 'Synced',),)
          .called(1);
      verify(mockDb.upsertSyncMetrics(any, any, 1, 1, 0, 0)).called(1);
    });

    test('on API failure increments failed counter and updates retry count',
        () async {
      final item = makeQueueItem(id: 'q1', operationType: 'create_case');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.post(any, data: anyNamed('data')))
          .thenThrow(Exception('network error'));

      await sut.syncPendingOperations();

      verify(mockDb.updateSyncQueueRetryCount('q1', 1)).called(1);
      verify(mockDb.addSyncActivity(
              'q1', 'q1', 'case', 'create_case', 'failure', any,),)
          .called(1);
      verify(mockDb.upsertSyncMetrics(any, any, 1, 0, 1, 0)).called(1);
    });
  });

  // ── update_case ──────────────────────────────────────────────────────────────

  group('update_case', () {
    test('puts to /api/cases/:id and upserts locally', () async {
      final payload = {'caseId': 'c1', 'tenantId': 't1', 'title': 'Updated'};
      final item = makeQueueItem(
          id: 'q2', operationType: 'update_case', payload: payload,);
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.put('/api/cases/c1', data: anyNamed('data')))
          .thenAnswer((_) async => mapResponse(payload));
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});

      await sut.syncPendingOperations();

      verify(mockApi.put('/api/cases/c1', data: anyNamed('data'))).called(1);
      verify(mockDb.upsertCase('c1', payload, tenantId: 't1'))
          .called(1);
      verify(mockDb.removeSyncQueueItem('q2')).called(1);
    });

    test('409 conflict falls back to local payload without context', () async {
      final payload = {'caseId': 'c1', 'tenantId': 't1'};
      final item = makeQueueItem(
          id: 'q3', operationType: 'update_case', payload: payload,);
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.put('/api/cases/c1', data: anyNamed('data')))
          .thenThrow(_dioError(409));
      when(mockApi.get('/api/cases/c1', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async =>
              mapResponse({'caseId': 'c1', 'tenantId': 't1', 'title': 'Remote'}),);
      when(mockApi.put('/api/cases/c1', data: anyNamed('data')))
          .thenAnswer((_) async => mapResponse(payload));
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});

      await sut.syncPendingOperations();

      // With null context, local payload wins — upsertCase called with local data
      verify(mockDb.upsertCase('c1', payload,
              tenantId: 't1',),)
          .called(1);
      verify(mockDb.removeSyncQueueItem('q3')).called(1);
    });

    test('non-409 DioException is treated as failure and retried', () async {
      final item = makeQueueItem(id: 'q4', operationType: 'update_case');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.put(any, data: anyNamed('data')))
          .thenThrow(_dioError(500));

      await sut.syncPendingOperations();

      verify(mockDb.updateSyncQueueRetryCount('q4', 1)).called(1);
      verify(mockDb.upsertSyncMetrics(any, any, 1, 0, 1, 0)).called(1);
    });
  });

  // ── delete_case ──────────────────────────────────────────────────────────────

  group('delete_case', () {
    test('deletes from API and local DB, removes from queue', () async {
      final item = makeQueueItem(id: 'q5', operationType: 'delete_case');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.delete('/api/cases/c1', data: anyNamed('data')))
          .thenAnswer((_) async => mapResponse({}));
      when(mockDb.deleteCase('c1')).thenAnswer((_) async {});

      await sut.syncPendingOperations();

      verify(mockApi.delete('/api/cases/c1', data: anyNamed('data'))).called(1);
      verify(mockDb.deleteCase('c1')).called(1);
      verify(mockDb.removeSyncQueueItem('q5')).called(1);
    });
  });

  // ── unsupported operation ────────────────────────────────────────────────────

  group('unsupported operation', () {
    test('counts as failure and logs activity', () async {
      final item = makeQueueItem(id: 'q6', operationType: 'unknown_op');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);

      await sut.syncPendingOperations();

      verify(mockDb.addSyncActivity(
              'q6', 'q6', 'case', 'unknown_op', 'failure', any,),)
          .called(1);
      verify(mockDb.upsertSyncMetrics(any, any, 1, 0, 1, 0)).called(1);
    });
  });

  // ── retry / max-retry logic ──────────────────────────────────────────────────

  group('retry logic', () {
    test('item at retryCount=2 that fails is removed after reaching limit',
        () async {
      final item = makeQueueItem(
          id: 'q7', operationType: 'create_case', retryCount: 2,);
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.post(any, data: anyNamed('data')))
          .thenThrow(Exception('fail'));

      await sut.syncPendingOperations();

      // retryCount goes to 3 → item removed
      verify(mockDb.updateSyncQueueRetryCount('q7', 3)).called(1);
      verify(mockDb.removeSyncQueueItem('q7')).called(1);
    });

    test('item already at retryCount=3 is dropped immediately without API call',
        () async {
      final item = makeQueueItem(
          id: 'q8', operationType: 'create_case', retryCount: 3,);
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);

      await sut.syncPendingOperations();

      verifyNever(mockApi.post(any));
      verify(mockDb.removeSyncQueueItem('q8')).called(1);
      verify(mockDb.addSyncActivity(
              'q8', 'q8', 'case', 'create_case', 'max_retries', any,),)
          .called(1);
      // dropped item counts as failed, not attempted
      verify(mockDb.upsertSyncMetrics(any, any, 0, 0, 1, 0)).called(1);
    });

    test('multiple items: success + failure tracked independently', () async {
      final good = makeQueueItem(
          id: 'q9', operationType: 'create_case', entityId: 'c9',);
      final bad = makeQueueItem(
          id: 'q10', operationType: 'create_case', entityId: 'c10',);
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [good, bad]);
      when(mockApi.post('/api/cases', data: anyNamed('data')))
          .thenAnswer((inv) async {
        final data = inv.namedArguments[#data] as Map<String, dynamic>;
        if (data['caseId'] == 'c9') {
          return mapResponse({'caseId': 'c9', 'tenantId': 't1'});
        }
        throw Exception('fail c10');
      });
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});

      await sut.syncPendingOperations();

      verify(mockDb.upsertSyncMetrics(any, any, 2, 1, 1, 0)).called(1);
    });
  });

  // ── getSyncHealth ────────────────────────────────────────────────────────────

  group('getSyncHealth', () {
    test('reflects counters after processing', () async {
      final item = makeQueueItem(id: 'q11', operationType: 'create_case');
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => [item]);
      when(mockApi.post(any, data: anyNamed('data')))
          .thenAnswer((_) async =>
              mapResponse({'caseId': 'c1', 'tenantId': 't1'}),);
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});

      await sut.syncPendingOperations();
      final health = sut.getSyncHealth();

      expect(health.attempted, 1);
      expect(health.succeeded, 1);
      expect(health.failed, 0);
      expect(health.canceled, 0);
    });
  });

  // ── loadPersistedHealth ──────────────────────────────────────────────────────

  group('loadPersistedHealth', () {
    test('returns null when no metrics row exists', () async {
      when(mockDb.getSyncMetrics('default')).thenAnswer((_) async => null);

      final result = await sut.loadPersistedHealth();

      expect(result, isNull);
    });

    test('deserialises stored row correctly', () async {
      when(mockDb.getSyncMetrics('default')).thenAnswer((_) async => {
            'attempted': 10,
            'succeeded': 8,
            'failed': 2,
            'canceled': 0,
            'lastSyncAt': '2024-01-15T10:00:00.000',
          },);

      final health = await sut.loadPersistedHealth();

      expect(health, isNotNull);
      expect(health!.attempted, 10);
      expect(health.succeeded, 8);
      expect(health.failed, 2);
      expect(health.canceled, 0);
      expect(health.lastSyncAt, DateTime.parse('2024-01-15T10:00:00.000'));
    });
  });

  // ── performFullSync / reconciliation pipeline ────────────────────────────────

  group('performFullSync — reconciliation pipeline', () {
    setUp(() {
      when(mockDb.getSyncQueueItems()).thenAnswer((_) async => []);
      when(mockDb.upsertCase(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});
      when(mockDb.upsertHearing(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});
      when(mockDb.upsertCustomer(any, any, tenantId: anyNamed('tenantId')))
          .thenAnswer((_) async {});
      when(mockDb.upsertDocument(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});
      when(mockDb.upsertEmployee(any, any,
              tenantId: anyNamed('tenantId'),),)
          .thenAnswer((_) async {});
      when(mockDb.upsertDashboard(any, any, tenantId: anyNamed('tenantId')))
          .thenAnswer((_) async {});
    });

    test('fetches all 6 entity endpoints and upserts each item', () async {
      when(mockApi.get('/api/cases',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'caseId': 'c1', 'tenantId': 't1'},
                {'caseId': 'c2', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/sitings',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'hearingId': 'h1', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/customers',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'customerId': 'cu1', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/files',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'id': 'd1'},
                {'id': 'd2'},
              ]),);
      when(mockApi.get('/api/employees',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'id': 'e1', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/dashboard',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async =>
              mapResponse({'totalCases': 5, 'openCases': 2}),);

      await sut.performFullSync();

      verify(mockDb.upsertCase('c1', any, tenantId: 't1'))
          .called(1);
      verify(mockDb.upsertCase('c2', any, tenantId: 't1'))
          .called(1);
      verify(mockDb.upsertHearing('h1', any, tenantId: 't1'))
          .called(1);
      verify(mockDb.upsertCustomer('cu1', any, tenantId: 't1')).called(1);
      verify(mockDb.upsertDocument('d1', any,),)
          .called(1);
      verify(mockDb.upsertDocument('d2', any,),)
          .called(1);
      verify(mockDb.upsertEmployee('e1', any, tenantId: 't1'))
          .called(1);
      verify(mockDb.upsertDashboard('default', any)).called(1);
    });

    test('skips items with empty id without throwing', () async {
      when(mockApi.get('/api/cases',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'caseId': '', 'tenantId': 't1'}, // empty id — must be skipped
                {'caseId': 'c1', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/sitings',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/customers',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/files',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/employees',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/dashboard',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => mapResponse({}));

      await sut.performFullSync();

      // Only c1 upserted, empty-id item skipped
      verify(mockDb.upsertCase('c1', any,
              tenantId: anyNamed('tenantId'),),)
          .called(1);
      verifyNever(mockDb.upsertCase('', any,
          tenantId: anyNamed('tenantId'),),);
    });

    test('one failing endpoint does not abort the others', () async {
      when(mockApi.get('/api/cases',
              queryParameters: anyNamed('queryParameters'),),)
          .thenThrow(_networkError()); // cases endpoint fails
      when(mockApi.get('/api/sitings',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([
                {'hearingId': 'h1', 'tenantId': 't1'},
              ]),);
      when(mockApi.get('/api/customers',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/files',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/employees',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/dashboard',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => mapResponse({}));

      // Must complete without throwing
      await expectLater(sut.performFullSync(), completes);

      // Hearings still upserted despite cases failing
      verify(mockDb.upsertHearing('h1', any,
              tenantId: 't1',),)
          .called(1);
      verifyNever(mockDb.upsertCase(any, any,
          tenantId: anyNamed('tenantId'),),);
    });

    test('dashboard endpoint returning non-map is silently ignored', () async {
      when(mockApi.get('/api/cases',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/sitings',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/customers',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/files',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/employees',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async => listResponse([]));
      when(mockApi.get('/api/dashboard',
              queryParameters: anyNamed('queryParameters'),),)
          .thenAnswer((_) async =>
              Response(data: 'not-a-map', // wrong type
                  statusCode: 200,
                  requestOptions: RequestOptions(),),);

      await expectLater(sut.performFullSync(), completes);
      verifyNever(mockDb.upsertDashboard(any, any));
    });
  });
}
