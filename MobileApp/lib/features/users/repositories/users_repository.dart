import '../../../core/api/api_client.dart';

class UsersRepository {
  final ApiClient apiClient;

  UsersRepository(this.apiClient);

  Future<List<Map<String, dynamic>>> getUsers({String? search}) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await apiClient.get('/users', queryParameters: query.isEmpty ? null : query);
    final data = response.data;

    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    return const [];
  }
}
