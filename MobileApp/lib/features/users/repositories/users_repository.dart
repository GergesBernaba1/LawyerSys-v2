import 'package:qadaya_lawyersys/core/api/api_client.dart';

class UsersRepository {

  UsersRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<Map<String, dynamic>>> getUsers({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiClient.get('/users', queryParameters: query.isEmpty ? null : query);
    final data = response.data;

    if (data is List) {
      return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
    }

    return const [];
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? job,
    String role = 'Employee',
  }) async {
    await apiClient.post('/users', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'job': job,
      'role': role,
    },);
  }

  Future<void> updateUser(
    String id, {
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? job,
    bool isActive = true,
  }) async {
    await apiClient.put('/users/$id', data: {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'job': job,
      'isActive': isActive,
    },);
  }

  Future<void> deleteUser(String id) async {
    await apiClient.delete('/users/$id');
  }

  Future<void> changeUserRole(String id, String role) async {
    await apiClient.put('/users/$id/role', data: {'role': role});
  }
}
