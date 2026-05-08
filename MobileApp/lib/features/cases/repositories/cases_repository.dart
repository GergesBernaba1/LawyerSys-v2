import 'dart:convert';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/core/sync/sync_queue_item.dart';
import 'package:qadaya_lawyersys/features/cases/models/case.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';

class CasesRepository {

  CasesRepository(this.apiClient, this.localDatabase);
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List<dynamic>) return items;
    }
    return const [];
  }

  Future<List<CaseModel>> getCases(
      {String? tenantId, int page = 1, int pageSize = 20,}) async {
    try {
      final response = await apiClient.get('/api/cases',
          queryParameters: {'page': page, 'pageSize': pageSize},);
      final list = _asList(response.data)
          .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      for (final c in list) {
        await localDatabase.upsertCase(c.caseId, c.toJson(),
            tenantId: c.tenantId.isNotEmpty ? c.tenantId : tenantId,);
      }
      return list;
    } catch (_) {
      final safePage = page <= 0 ? 1 : page;
      final cached = await localDatabase.getCases(
          tenantId: tenantId,
          limit: pageSize,
          offset: (safePage - 1) * pageSize,);
      return cached
          .map((row) => CaseModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .toList();
    }
  }

  Future<CaseModel?> getCaseById(String caseId) async {
    try {
      final response = await apiClient.get('/api/cases/$caseId');
      if (response.data != null) {
        final model =
            CaseModel.fromJson(Map<String, dynamic>.from(response.data as Map));
        await localDatabase.upsertCase(model.caseId, model.toJson(),
            tenantId: model.tenantId,);
        return model;
      }
      return null;
    } catch (_) {
      final cached = await localDatabase.getCases();
      return cached
          .map((row) => CaseModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .firstWhere((e) => e.caseId == caseId,
              orElse: () => throw StateError('Case not found'),);
    }
  }

  Future<void> createCase(CaseModel caseModel) async {
    try {
      final response =
          await apiClient.post('/api/cases', data: caseModel.toJson());
      final created =
          CaseModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      await localDatabase.upsertCase(created.caseId, created.toJson(),
          tenantId: created.tenantId,);
    } catch (_) {
      // fallback offline create
      await localDatabase.upsertCase(caseModel.caseId, caseModel.toJson(),
          tenantId: caseModel.tenantId, isDirty: true,);
      await localDatabase.addSyncQueueItem(SyncQueueItem(
        id: 'create_case_${caseModel.caseId}_${DateTime.now().millisecondsSinceEpoch}',
        operationType: 'create_case',
        entityType: 'case',
        entityId: caseModel.caseId,
        payload: caseModel.toJson(),
      ),);
      rethrow;
    }
  }

  Future<void> updateCase(CaseModel caseModel) async {
    try {
      await apiClient.put('/api/cases/${caseModel.caseId}',
          data: caseModel.toJson(),);
      await localDatabase.upsertCase(caseModel.caseId, caseModel.toJson(),
          tenantId: caseModel.tenantId,);
    } catch (_) {
      await localDatabase.upsertCase(caseModel.caseId, caseModel.toJson(),
          tenantId: caseModel.tenantId, isDirty: true,);
      await localDatabase.addSyncQueueItem(SyncQueueItem(
        id: 'update_case_${caseModel.caseId}_${DateTime.now().millisecondsSinceEpoch}',
        operationType: 'update_case',
        entityType: 'case',
        entityId: caseModel.caseId,
        payload: caseModel.toJson(),
      ),);
      rethrow;
    }
  }

  Future<void> deleteCase(String caseId) async {
    try {
      await apiClient.delete('/api/cases/$caseId');
      await localDatabase.deleteCase(caseId);
    } catch (_) {
      await localDatabase.deleteCase(caseId);
      await localDatabase.addSyncQueueItem(SyncQueueItem(
        id: 'delete_case_${caseId}_${DateTime.now().millisecondsSinceEpoch}',
        operationType: 'delete_case',
        entityType: 'case',
        entityId: caseId,
        payload: {},
      ),);
      rethrow;
    }
  }

  Future<List<CaseModel>> searchCases(String query, {String? tenantId}) async {
    try {
      final response =
          await apiClient.get('/api/cases', queryParameters: {'search': query});
      return _asList(response.data)
          .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      final cached =
          await localDatabase.getCases(tenantId: tenantId, limit: 200);
      return cached
          .map((row) => CaseModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .where((c) =>
              c.caseNumber.toLowerCase().contains(query.toLowerCase()) ||
              c.invitionType.toLowerCase().contains(query.toLowerCase()) ||
              c.invitionsStatment.toLowerCase().contains(query.toLowerCase()),)
          .toList();
    }
  }

  Future<void> changeStatus(String caseCode, int status) async {
    await apiClient.post('/api/cases/$caseCode/status', data: {'status': status});
  }

  Future<List<Map<String, dynamic>>> getStatusHistory(String caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/status-history');
    final data = response.data;
    final list = data is List ? data : (data is Map ? (data['items'] ?? data['data'] ?? <dynamic>[]) : <dynamic>[]);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  Future<List<CustomerCaseHistoryItem>> getCasesByCustomerId(String customerId,
      {String? tenantId,}) async {
    // Prefer backend profile endpoint for exact customer-case relationships.
    try {
      final response =
          await apiClient.get('/api/customers/$customerId/profile');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final casesData = (response.data as Map<String, dynamic>)['cases'];
        if (casesData is List<dynamic>) {
          return casesData
              .map((e) => CustomerCaseHistoryItem.fromJson(
                  Map<String, dynamic>.from(e as Map),),)
              .toList();
        }
      }
    } catch (_) {
      // fallback to local cache
    }

    final cached =
        await localDatabase.getCases(tenantId: tenantId, limit: 200);
    return cached
        .map((row) => CaseModel.fromJson(
            jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
        .where((c) => c.customerId == customerId)
        .map((caseModel) => CustomerCaseHistoryItem(
              caseId: caseModel.caseId,
              caseName: caseModel.caseNumber,
              caseCode: caseModel.caseNumber,
              assignedEmployeeName: caseModel.assignedEmployees.isNotEmpty
                  ? caseModel.assignedEmployees.first.employeeName
                  : '',
            ),)
        .toList();
  }
}
