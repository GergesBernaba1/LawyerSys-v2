import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../storage/local_database.dart';
import 'sync_queue_item.dart';
import 'conflict_resolver.dart';

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
  int _canceled = 0;

  SyncService({ApiClient? apiClient, LocalDatabase? localDatabase})
      : _apiClient = apiClient ?? ApiClient(),
        _localDatabase = localDatabase ?? LocalDatabase.instance;

  Future<void> syncPendingOperations(BuildContext? context) async {
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
        await _processQueueItem(item, context);
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

  Future<void> _processQueueItem(SyncQueueItem item, BuildContext? context) async {
    switch (item.operationType) {
      case 'create_case':
        await _createCaseSync(item);
        break;
      case 'update_case':
        await _updateCaseSync(item, context);
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

  Future<void> _updateCaseSync(SyncQueueItem item, BuildContext? context) async {
    try {
      await _apiClient.put('/api/cases/${item.entityId}', data: item.payload);
      await _localDatabase.upsertCase(item.entityId, item.payload, tenantId: item.payload['tenantId'] as String? ?? '', isDirty: false);
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 409) {
        await _handleCaseConflict(item, context);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteCaseSync(SyncQueueItem item) async {
    await _apiClient.delete('/api/cases/${item.entityId}');
    await _localDatabase.deleteCase(item.entityId);
  }

  Future<void> _handleCaseConflict(SyncQueueItem item, BuildContext? context) async {
    try {
      final remoteResponse = await _apiClient.get('/api/cases/${item.entityId}');
      if (remoteResponse.data == null || remoteResponse.data is! Map<String, dynamic>) return;

      final remote = Map<String, dynamic>.from(remoteResponse.data as Map);
      final local = Map<String, dynamic>.from(item.payload);

      Map<String, dynamic> resolved;
      if (context != null) {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => ConflictResolverWidget(
            entityName: 'Case',
            localData: local,
            remoteData: remote,
          ),
        );
        resolved = result ?? local;
      } else {
        resolved = local;
      }

      await _apiClient.put('/api/cases/${item.entityId}', data: resolved);
      await _localDatabase.upsertCase(item.entityId, resolved, tenantId: resolved['tenantId'] as String? ?? '', isDirty: false);
    } catch (error) {
      debugPrint('SyncService conflict resolution failed for case ${item.entityId}: $error');
      rethrow;
    }
  }

  Future<void> performFullSync(BuildContext? context) async {
    await syncPendingOperations(context);
    // TODO: Add full data reconciliation pipeline (cases, hearings, customers, docs, etc.)
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


