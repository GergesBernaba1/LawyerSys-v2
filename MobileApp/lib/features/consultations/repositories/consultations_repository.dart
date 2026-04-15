import '../../../core/api/api_client.dart';
import '../models/consultation.dart';

class RelationOption {
  final int id;
  final String name;

  const RelationOption({required this.id, required this.name});
}

class ConsultationsRepository {
  final ApiClient apiClient;

  ConsultationsRepository(this.apiClient);

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List<dynamic>) return items;
    }
    return const [];
  }

  Future<List<ConsultationModel>> getConsultations({int page = 1, int pageSize = 20}) async {
    final response = await apiClient.get('/consulations', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = _asList(response.data);
    return data
        .whereType<Map>()
        .map((e) => ConsultationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConsultationModel?> getConsultationById(int id) async {
    final response = await apiClient.get('/consulations/$id');
    if (response.data == null) return null;
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ConsultationModel> createConsultation(ConsultationModel consultation) async {
    final response = await apiClient.post('/consulations', data: consultation.toJson());
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<ConsultationModel> updateConsultation(ConsultationModel consultation) async {
    final response = await apiClient.put('/consulations/${consultation.id}', data: consultation.toJson());
    return ConsultationModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteConsultation(int id) async {
    await apiClient.delete('/consulations/$id');
  }

  Future<List<ConsultationModel>> searchConsultations(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      return getConsultations();
    }
    final response = await apiClient.get('/consulations', queryParameters: {'search': keyword});
    final data = _asList(response.data);
    return data
        .whereType<Map>()
        .map((e) => ConsultationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<RelationOption>> getCustomerOptions() async {
    final response = await apiClient.get('/customers');
    final data = _asList(response.data);
    return data.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      final id = int.tryParse((item['id'] ?? item['Id'] ?? 0).toString()) ?? 0;
      final user = item['user'] is Map
          ? Map<String, dynamic>.from(item['user'] as Map)
          : item['User'] is Map
              ? Map<String, dynamic>.from(item['User'] as Map)
              : <String, dynamic>{};
      final name = (user['fullName'] ??
              user['FullName'] ??
              user['email'] ??
              user['Email'] ??
              '#$id')
          .toString();
      return RelationOption(id: id, name: name);
    }).toList();
  }

  Future<List<RelationOption>> getEmployeeOptions() async {
    final response = await apiClient.get('/employees');
    final data = _asList(response.data);
    return data.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
      final id = int.tryParse((item['id'] ?? item['Id'] ?? 0).toString()) ?? 0;
      final user = item['user'] is Map
          ? Map<String, dynamic>.from(item['user'] as Map)
          : item['User'] is Map
              ? Map<String, dynamic>.from(item['User'] as Map)
              : <String, dynamic>{};
      final identity = item['identity'] is Map
          ? Map<String, dynamic>.from(item['identity'] as Map)
          : item['Identity'] is Map
              ? Map<String, dynamic>.from(item['Identity'] as Map)
              : <String, dynamic>{};
      final name = (user['fullName'] ??
              user['FullName'] ??
              identity['fullName'] ??
              identity['FullName'] ??
              user['email'] ??
              user['Email'] ??
              identity['email'] ??
              identity['Email'] ??
              '#$id')
          .toString();
      return RelationOption(id: id, name: name);
    }).toList();
  }

  Future<List<int>> getConsultationCustomerIds(int consultationId) async {
    final response = await apiClient.get('/consulations/$consultationId/customers');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => int.tryParse(
                (row['customerId'] ?? row['CustomerId'] ?? 0).toString()) ??
            0)
        .where((id) => id > 0)
        .toList();
  }

  Future<List<int>> getConsultationEmployeeIds(int consultationId) async {
    final response = await apiClient.get('/consulations/$consultationId/employees');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => int.tryParse(
                (row['employeeId'] ?? row['EmployeeId'] ?? 0).toString()) ??
            0)
        .where((id) => id > 0)
        .toList();
  }

  Future<void> syncConsultationRelations({
    required int consultationId,
    required Set<int> selectedCustomerIds,
    required Set<int> selectedEmployeeIds,
    required bool includeEmployees,
  }) async {
    final existingCustomers = (await getConsultationCustomerIds(consultationId)).toSet();
    final existingEmployees = (await getConsultationEmployeeIds(consultationId)).toSet();

    final customersToAdd = selectedCustomerIds.difference(existingCustomers);
    final customersToRemove = existingCustomers.difference(selectedCustomerIds);

    for (final id in customersToAdd) {
      await apiClient.post('/consulations/$consultationId/customers/$id');
    }
    for (final id in customersToRemove) {
      await apiClient.delete('/consulations/$consultationId/customers/$id');
    }

    if (!includeEmployees) return;

    final employeesToAdd = selectedEmployeeIds.difference(existingEmployees);
    final employeesToRemove = existingEmployees.difference(selectedEmployeeIds);

    for (final id in employeesToAdd) {
      await apiClient.post('/consulations/$consultationId/employees/$id');
    }
    for (final id in employeesToRemove) {
      await apiClient.delete('/consulations/$consultationId/employees/$id');
    }
  }
}
