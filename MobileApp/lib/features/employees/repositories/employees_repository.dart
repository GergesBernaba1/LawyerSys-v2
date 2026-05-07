import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/employees/models/employee.dart';

class EmployeesRepository {

  EmployeesRepository(this.apiClient, this.localDatabase);
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

  Future<List<EmployeeModel>> getEmployees(
      {String? tenantId, int page = 1, int pageSize = 20,}) async {
    try {
      final response = await apiClient.get('/employees',
          queryParameters: {'page': page, 'pageSize': pageSize},);
      final list = _asList(response.data)
          .map((e) =>
              EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)),)
          .toList();
      for (final emp in list) {
        await localDatabase.upsertEmployee(emp.id.toString(), emp.toJson(),
            tenantId: tenantId,);
      }
      return list;
    } catch (_) {
      final safePage = page <= 0 ? 1 : page;
      final cached = await localDatabase.getEmployees(
          tenantId: tenantId,
          limit: pageSize,
          offset: (safePage - 1) * pageSize,);
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .toList();
    }
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      final response = await apiClient.get('/employees/$id');
      if (response.data != null) {
        final model =
            EmployeeModel.fromJson(Map<String, dynamic>.from(response.data as Map));
        await localDatabase.upsertEmployee(model.id.toString(), model.toJson(),);
        return model;
      }
      return null;
    } catch (_) {
      final cached = await localDatabase.getEmployees();
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .firstWhere((e) => e.id == id,
              orElse: () => throw StateError('Employee not found'),);
    }
  }

  Future<void> createEmployee(EmployeeModel employee) async {
    try {
      final response = await apiClient.post('/employees',
          data: {
            'usersId': employee.usersId,
            'salary': employee.salary,
          },);
      if (response.data is Map<String, dynamic>) {
        final created = EmployeeModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),);
        await localDatabase.upsertEmployee(
            created.id.toString(), created.toJson(),);
      } else {
        await localDatabase.upsertEmployee(
            employee.id.toString(), employee.toJson(),);
      }
    } catch (_) {
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: true,);
      rethrow;
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await apiClient.put('/employees/${employee.id}',
          data: {
            // Backend UpdateEmployeeDto accepts salary only.
            'salary': employee.salary,
          },);
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),);
    } catch (_) {
      await localDatabase.upsertEmployee(
          employee.id.toString(), employee.toJson(),
          isDirty: true,);
      rethrow;
    }
  }

  Future<void> deleteEmployee(int employeeId) async {
    await apiClient.delete('/employees/$employeeId');
    await localDatabase.deleteEmployee(employeeId.toString());
  }

  Future<void> uploadProfileImage(int employeeId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    await apiClient.post('/employees/$employeeId/profile-image', data: formData);
  }

  Future<List<EmployeeModel>> searchEmployees(String query,
      {String? tenantId,}) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      return getEmployees(tenantId: tenantId);
    }

    try {
      final response = await apiClient
          .get('/employees', queryParameters: {'search': keyword});
      return _asList(response.data)
          .map((e) =>
              EmployeeModel.fromJson(Map<String, dynamic>.from(e as Map)),)
          .toList();
    } catch (_) {
      final cached =
          await localDatabase.getEmployees(tenantId: tenantId, limit: 200);
      return cached
          .map((row) => EmployeeModel.fromJson(
              jsonDecode(row['data'] as String) as Map<String, dynamic>,),)
          .where((e) =>
              (e.user?.fullName
                      .toLowerCase()
                      .contains(keyword.toLowerCase()) ??
                  false) ||
              (e.user?.userName.toLowerCase().contains(keyword.toLowerCase()) ??
                  false) ||
              (e.user?.job.toLowerCase().contains(keyword.toLowerCase()) ??
                  false),)
          .toList();
    }
  }
}
