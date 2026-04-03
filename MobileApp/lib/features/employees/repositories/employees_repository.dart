import 'dart:convert';

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_database.dart';
import '../models/employee.dart';

class EmployeesRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  EmployeesRepository(this.apiClient, this.localDatabase);

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List<dynamic>) return items;
    }
    return const [];
  }

  Future<List<EmployeeModel>> getEmployees(
      {String? tenantId, int page = 1, int pageSize = 20}) async {
    try {
      final response = await apiClient.get('/api/employees',
          queryParameters: {'page': page, 'pageSize': pageSize});
      final list = _asList(response.data)
          .map((e) =>
              EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      for (final emp in list) {
        await localDatabase.upsertEmployee(emp.id.toString(), emp.toJson(),
            tenantId: tenantId, isDirty: false);
      }
      return list;
    } catch (_) {
      final safePage = page <= 0 ? 1 : page;
      final cached = await localDatabase.getEmployees(
          tenantId: tenantId,
          limit: pageSize,
          offset: (safePage - 1) * pageSize);
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      final response = await apiClient.get('/api/employees/$id');
      if (response.data != null) {
        final model =
            EmployeeModel.fromJson(Map<String, dynamic>.from(response.data));
        await localDatabase.upsertEmployee(model.id.toString(), model.toJson(),
            isDirty: false);
        return model;
      }
      return null;
    } catch (_) {
      final cached = await localDatabase.getEmployees();
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .firstWhere((e) => e.id == id,
              orElse: () => throw StateError('Employee not found'));
    }
  }

  Future<void> createEmployee(EmployeeModel employee) async {
    try {
      await apiClient.post('/api/employees', data: employee.toJson());
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: false);
    } catch (_) {
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: true);
      rethrow;
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await apiClient.put('/api/employees/${employee.id}',
          data: employee.toJson());
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: false);
    } catch (_) {
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: true);
      rethrow;
    }
  }

  Future<void> deleteEmployee(int employeeId) async {
    await apiClient.delete('/api/employees/$employeeId');
  }

  Future<List<EmployeeModel>> searchEmployees(String query,
      {String? tenantId}) async {
    try {
      final response = await apiClient
          .get('/api/employees', queryParameters: {'search': query});
      return _asList(response.data)
          .map((e) =>
              EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      final cached =
          await localDatabase.getEmployees(tenantId: tenantId, limit: 200);
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .where((e) =>
              (e.user?.fullName
                      .toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false) ||
              (e.user?.userName.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (e.user?.job.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    }
  }
}
