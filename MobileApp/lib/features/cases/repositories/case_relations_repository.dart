import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/cases/models/case_relation.dart';

class CaseRelationsRepository {
  CaseRelationsRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<CaseRelation>> getRelations(int caseId) async {
    final response = await apiClient.get('/CaseRelations', queryParameters: {'caseId': caseId});
    final data = response.data;
    final list = data is List ? data : (data is Map ? (data['items'] ?? data['data'] ?? <dynamic>[]) : <dynamic>[]);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map((e) => CaseRelation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createRelation(
    int caseId,
    int relatedCaseId,
    String relationType, {
    String? notes,
  }) async {
    await apiClient.post('/CaseRelations', data: {
      'caseId': caseId,
      'relatedCaseId': relatedCaseId,
      'relationType': relationType,
      if (notes != null) 'notes': notes,
    },);
  }

  Future<void> deleteRelation(int id) async {
    await apiClient.delete('/CaseRelations/$id');
  }

  // ── Entity linking ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCaseCustomers(String caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/customers');
    return _toList(response.data);
  }

  Future<void> addCustomerToCase(String caseCode, String customerId) async {
    await apiClient.post('/api/cases/$caseCode/customers/$customerId');
  }

  Future<void> removeCustomerFromCase(String caseCode, String customerId) async {
    await apiClient.delete('/api/cases/$caseCode/customers/$customerId');
  }

  Future<List<Map<String, dynamic>>> getCaseCourts(String caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/courts');
    return _toList(response.data);
  }

  Future<void> addCourtToCase(String caseCode, String courtId) async {
    await apiClient.post('/api/cases/$caseCode/courts/$courtId');
  }

  Future<void> removeCourtFromCase(String caseCode, String courtId) async {
    await apiClient.delete('/api/cases/$caseCode/courts/$courtId');
  }

  Future<List<Map<String, dynamic>>> getCaseContenders(String caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/contenders');
    return _toList(response.data);
  }

  Future<void> addContenderToCase(String caseCode, String contenderId) async {
    await apiClient.post('/api/cases/$caseCode/contenders/$contenderId');
  }

  Future<void> removeContenderFromCase(
      String caseCode, String contenderId,) async {
    await apiClient.delete('/api/cases/$caseCode/contenders/$contenderId');
  }

  Future<List<Map<String, dynamic>>> getCaseEmployees(String caseCode) async {
    final response = await apiClient.get('/api/cases/$caseCode/employees');
    return _toList(response.data);
  }

  Future<void> addEmployeeToCase(String caseCode, String employeeId) async {
    await apiClient.post('/api/cases/$caseCode/employees/$employeeId');
  }

  Future<void> removeEmployeeFromCase(
      String caseCode, String employeeId,) async {
    await apiClient.delete('/api/cases/$caseCode/employees/$employeeId');
  }

  List<Map<String, dynamic>> _toList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['items'] ?? data['data'] ?? <dynamic>[]) : <dynamic>[]);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }
}
