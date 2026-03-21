import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/storage/local_database.dart';
import '../employees/models/employee.dart';

class EmployeesRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  EmployeesRepository(this.apiClient, this.localDatabase);

  Future<List<EmployeeModel>> getEmployees({String? tenantId, int page = 0, int pageSize = 20}) async {
    try {
      final response = await apiClient.get('/api/employees', queryParameters: {'page': page, 'size': pageSize});
      final list = (response.data as List<dynamic>?)?.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      for (final emp in list) {
        await localDatabase.upsertEmployee(emp.id.toString(), emp.toJson(), tenantId: tenantId, isDirty: false);
      }
      return list;
    } catch (_) {
      final cached = await localDatabase.getEmployees(tenantId: tenantId, limit: pageSize, offset: page * pageSize);
      return cached
          .map((row) => EmployeeModel.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      final response = await apiClient.get('/api/employees/$id');
      if (response.data != null) {
        final model = EmployeeModel.fromJson(Map<String, dynamic>.from(response.data));
        await localDatabase.upsertEmployee(model.id.toString(), model.toJson(), isDirty: false);
        return model;
      }
      return null;
    } catch (_) {
      final cached = await localDatabase.getEmployees();
      return cached
          .map((row) => EmployeeModel.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .firstWhere((e) => e.id == id, orElse: () => throw StateError('Employee not found'));
    }
  }

  Future<void> createEmployee(EmployeeModel employee) async {
    try {
      await apiClient.post('/api/employees', data: employee.toJson());
      await localDatabase.upsertEmployee(employee.id.toString(), employee.toJson(), isDirty: false);
    } catch (_) {
      await localDatabase.upsertEmployee(employee.id.toString(), employee.toJson(), isDirty: true);
      rethrow;
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await apiClient.put('/api/employees/${employee.id}', data: employee.toJson());
      await localDatabase.upsertEmployee(employee.id.toString(), employee.toJson(), isDirty: false);
    } catch (_) {
      await localDatabase.upsertEmployee(employee.id.toString(), employee.toJson(), isDirty: true);
      rethrow;
    }
  }

  Future<List<EmployeeModel>> searchEmployees(String query, {String? tenantId}) async {
    try {
      final response = await apiClient.get('/api/employees/search', queryParameters: {'q': query});
      return (response.data as List<dynamic>?)?.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    } catch (_) {
      final cached = await localDatabase.getEmployees(tenantId: tenantId, limit: 200);
      return cached
          .map((row) => EmployeeModel.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
          .where((e) =>
            e.user?.fullName.toLowerCase().contains(query.toLowerCase()) ||
            e.user?.userName.toLowerCase().contains(query.toLowerCase()) ||
            e.user?.job.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
