import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/customer.dart';

class CustomersRepository {
  final ApiClient apiClient;

  CustomersRepository(this.apiClient);

  Future<List<Customer>> getCustomers({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/customers', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final response = await apiClient.get('/api/customers/$customerId');
    if (response.data == null) return null;
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await apiClient
        .get('/api/customers/search', queryParameters: {'q': query});
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/customers', data: data);
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Customer> updateCustomer(String customerId, Map<String, dynamic> data) async {
    final response = await apiClient.put('/api/customers/$customerId', data: data);
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCustomer(String customerId) async {
    await apiClient.delete('/api/customers/$customerId');
  }

  Future<void> uploadProfileImage(String customerId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    await apiClient.post('/customers/$customerId/profile-image', data: formData);
  }
}
