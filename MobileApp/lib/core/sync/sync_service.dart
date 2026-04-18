import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../storage/local_database.dart';
import 'sync_queue_item.dart';

typedef ConflictResolverCallback = Future<Map<String, dynamic>?> Function(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
);

class SyncHealth {
  final int attempted;
  final int succeeded;
  final int failed;
  final int canceled;
  final DateTime lastSyncAt;

  SyncHealth({required this.attempted, required this.succeeded, required this.failed, required this.canceled, required this.lastSyncAt});

  Map<String, dynamic> toJson() => {
        'attempted': attempted,
        'succeeded': succeeded,
        'failed': failed,
        'canceled': canceled,
        'lastSyncAt': lastSyncAt.toIso8601String(),
      };
}

class SyncService {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;

  int _attempted = 0;
  int _succeeded = 0;
  int _failed = 0;
  final int _canceled = 0;


  SyncService({ApiClient? apiClient, LocalDatabase? localDatabase})
      : _apiClient = apiClient ?? ApiClient(),
        _localDatabase = localDatabase ?? LocalDatabase.instance;

  Future<void> syncPendingOperations([ConflictResolverCallback? conflictResolver]) async {
    final queue = await _localDatabase.getSyncQueueItems();
    for (final item in queue) {
      if (item.retryCount >= 3) {
        debugPrint('SyncService: item ${item.id} max retries reached, deleting');
        _failed += 1;
        await _localDatabase.removeSyncQueueItem(item.id);
        await _localDatabase.addSyncActivity(item.id, item.id, item.entityType, item.operationType, 'max_retries', 'Dropped after max retries');
        continue;
      }

      _attempted += 1;
      try {
        await _processQueueItem(item, conflictResolver);
        _succeeded += 1;
        await _localDatabase.removeSyncQueueItem(item.id);
        await _localDatabase.addSyncActivity(item.id, item.id, item.entityType, item.operationType, 'success', 'Synced');
      } catch (error) {
        _failed += 1;
        debugPrint('SyncService: failed item ${item.id}, error: $error');
        await _localDatabase.addSyncActivity(item.id, item.id, item.entityType, item.operationType, 'failure', error.toString());

        final nextRetryCount = item.retryCount + 1;
        await _localDatabase.updateSyncQueueRetryCount(item.id, nextRetryCount);

        if (nextRetryCount >= 3) {
          debugPrint('SyncService: item ${item.id} will be removed after retry exceeds limit');
          await _localDatabase.removeSyncQueueItem(item.id);
        }

        final backoffMs = 500 * (1 << (nextRetryCount - 1));
        await Future.delayed(Duration(milliseconds: backoffMs));
      }
    }

    await _persistHealthMetrics();
  }

  Future<void> _processQueueItem(SyncQueueItem item, ConflictResolverCallback? conflictResolver) async {
    switch (item.operationType) {
      case 'create_case':
        await _createCaseSync(item);
        break;
      case 'update_case':
        await _updateCaseSync(item, conflictResolver);
        break;
      case 'delete_case':
        await _deleteCaseSync(item);
        break;
      default:
        throw UnsupportedError('Unsupported sync operation: ${item.operationType}');
    }
  }

  Future<void> _createCaseSync(SyncQueueItem item) async {
    final response = await _apiClient.post('/api/cases', data: item.payload);
    if (response.data != null && response.data is Map<String, dynamic>) {
      final caseJson = Map<String, dynamic>.from(response.data as Map);
      await _localDatabase.upsertCase(item.entityId, caseJson, tenantId: caseJson['tenantId'] as String?, isDirty: false);
    }
  }

  Future<void> _updateCaseSync(SyncQueueItem item, ConflictResolverCallback? conflictResolver) async {
    try {
      await _apiClient.put('/api/cases/${item.entityId}', data: item.payload);
      await _localDatabase.upsertCase(item.entityId, item.payload, tenantId: item.payload['tenantId'] as String? ?? '', isDirty: false);
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 409) {
        await _handleCaseConflict(item, conflictResolver);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteCaseSync(SyncQueueItem item) async {
    await _apiClient.delete('/api/cases/${item.entityId}');
    await _localDatabase.deleteCase(item.entityId);
  }

  Future<void> _handleCaseConflict(SyncQueueItem item, ConflictResolverCallback? conflictResolver) async {
    try {
      final remoteResponse = await _apiClient.get('/api/cases/${item.entityId}');
      if (remoteResponse.data == null || remoteResponse.data is! Map<String, dynamic>) return;

      final remote = Map<String, dynamic>.from(remoteResponse.data as Map);
      final local = Map<String, dynamic>.from(item.payload);

      final resolved = conflictResolver != null
          ? await conflictResolver(local, remote) ?? local
          : local;

      await _apiClient.put('/api/cases/${item.entityId}', data: resolved);
      await _localDatabase.upsertCase(item.entityId, resolved, tenantId: resolved['tenantId'] as String? ?? '', isDirty: false);
    } catch (error) {
      debugPrint('SyncService conflict resolution failed for case ${item.entityId}: $error');
      rethrow;
    }
  }

  Future<void> performFullSync([ConflictResolverCallback? conflictResolver]) async {
    await syncPendingOperations(conflictResolver);
    await _reconcileAll();
  }

  Future<void> _reconcileAll() async {
    await Future.wait([
      _reconcile(
        label: 'cases',
        fetch: () => _apiClient.get('/api/cases', queryParameters: {'page': 0, 'size': 200}),
        upsert: (items) async {
          for (final item in items) {
            final id = item['caseId']?.toString() ?? '';
            if (id.isNotEmpty) await _localDatabase.upsertCase(id, item, tenantId: item['tenantId'] as String?, isDirty: false);
          }
        },
      ),
      _reconcile(
        label: 'hearings',
        fetch: () => _apiClient.get('/api/sitings', queryParameters: {'page': 1, 'pageSize': 200}),
        upsert: (items) async {
          for (final item in items) {
            final id = item['hearingId']?.toString() ?? '';
            if (id.isNotEmpty) await _localDatabase.upsertHearing(id, item, tenantId: item['tenantId'] as String?, isDirty: false);
          }
        },
      ),
      _reconcile(
        label: 'customers',
        fetch: () => _apiClient.get('/api/customers', queryParameters: {'page': 1, 'pageSize': 200}),
        upsert: (items) async {
          for (final item in items) {
            final id = item['customerId']?.toString() ?? '';
            if (id.isNotEmpty) await _localDatabase.upsertCustomer(id, item, tenantId: item['tenantId'] as String?);
          }
        },
      ),
      _reconcile(
        label: 'documents',
        fetch: () => _apiClient.get('/api/files'),
        upsert: (items) async {
          for (final item in items) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) await _localDatabase.upsertDocument(id, item, tenantId: item['tenantId'] as String?, isDownloaded: false);
          }
        },
      ),
      _reconcile(
        label: 'employees',
        fetch: () => _apiClient.get('/api/employees', queryParameters: {'page': 0, 'size': 200}),
        upsert: (items) async {
          for (final item in items) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await _localDatabase.upsertEmployee(
                id,
                item,
                tenantId: item['tenantId'] as String?,
                isDirty: false,
              );
            }
          }
        },
      ),
      _reconcileDashboard(),
    ]);
  }

  Future<void> _reconcile({
    required String label,
    required Future<dynamic> Function() fetch,
    required Future<void> Function(List<Map<String, dynamic>>) upsert,
  }) async {
    try {
      final response = await fetch();
      final raw = response.data;
      final List<dynamic> list = raw is List ? raw : [];
      final items = list.whereType<Map<String, dynamic>>().toList();
      await upsert(items);
      debugPrint('SyncService: reconciled $label (${items.length} items)');
    } catch (e) {
      debugPrint('SyncService: reconcile $label failed: $e');
    }
  }

  Future<void> _reconcileDashboard() async {
    try {
      final response = await _apiClient.get('/api/dashboard');
      if (response.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response.data as Map);
        await _localDatabase.upsertDashboard('default', data);
        debugPrint('SyncService: reconciled dashboard');
      }
    } catch (e) {
      debugPrint('SyncService: reconcile dashboard failed: $e');
    }
  }

  SyncHealth getSyncHealth() {
    return SyncHealth(
      attempted: _attempted,
      succeeded: _succeeded,
      failed: _failed,
      canceled: _canceled,
      lastSyncAt: DateTime.now(),
    );
  }

  Future<void> _persistHealthMetrics() async {
    final now = DateTime.now();
    await _localDatabase.upsertSyncMetrics('default', now, _attempted, _succeeded, _failed, _canceled);
  }

  Future<SyncHealth?> loadPersistedHealth() async {
    final row = await _localDatabase.getSyncMetrics('default');
    if (row == null) return null;
    return SyncHealth(
      attempted: row['attempted'] as int? ?? 0,
      succeeded: row['succeeded'] as int? ?? 0,
      failed: row['failed'] as int? ?? 0,
      canceled: row['canceled'] as int? ?? 0,
      lastSyncAt: DateTime.tryParse(row['lastSyncAt'] as String) ?? DateTime.now(),
    );
  }
}


