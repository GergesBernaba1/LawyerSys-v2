import '../../core/api/api_client.dart';
import '../customers/models/customer.dart';

class CustomersRepository {
  final ApiClient apiClient;

  CustomersRepository(this.apiClient);

  Future<List<Customer>> getCustomers({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/customers', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    final data = response.data as List<dynamic>?;
    if (data == null) return [];

    return data.map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final response = await apiClient.get('/api/customers/$customerId');
    if (response.data == null) return null;
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await apiClient.get('/api/customers/search', queryParameters: {'q': query});
    final data = response.data as List<dynamic>?;
    if (data == null) return [];
    return data.map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map))).toList();
  }
}
