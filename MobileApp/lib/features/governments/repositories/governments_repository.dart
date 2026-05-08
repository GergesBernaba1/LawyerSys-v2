import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/governments/models/government.dart';

class GovernmentsPage {
  GovernmentsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });
  final List<Government> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;
}

abstract class IGovernmentsRepository {
  Future<GovernmentsPage> getGovernments({
    int page = 1,
    int pageSize = GovernmentsRepository.defaultPageSize,
    String? search,
  });
  Future<Government> createGovernment(Map<String, dynamic> data);
  Future<Government> updateGovernment(String id, Map<String, dynamic> data);
  Future<void> deleteGovernment(String id);
}

class GovernmentsRepository implements IGovernmentsRepository {
  GovernmentsRepository(this.apiClient);
  final ApiClient apiClient;

  static const int defaultPageSize = 20;

  @override
  Future<GovernmentsPage> getGovernments({
    int page = 1,
    int pageSize = defaultPageSize,
    String? search,
  }) async {
    final response = await apiClient.get('/api/Governments', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
    },);
    final data = response.data;

    if (data is Map<String, dynamic> && data.containsKey('items')) {
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .map((e) => Government.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return GovernmentsPage(
        items: items,
        totalCount: (data['totalCount'] as int?) ?? items.length,
        page: page,
        pageSize: pageSize,
      );
    }

    // Non-paged fallback (shouldn't normally happen when params are sent)
    final rawList = data as List<dynamic>;
    final items = rawList
        .map((e) => Government.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return GovernmentsPage(
      items: items,
      totalCount: items.length,
      page: 1,
      pageSize: items.length.clamp(1, 9999),
    );
  }

  @override
  Future<Government> createGovernment(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/Governments', data: data);
    return Government.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<Government> updateGovernment(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/api/Governments/$id', data: data);
    return Government.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<void> deleteGovernment(String id) async {
    await apiClient.delete('/api/Governments/$id');
  }
}
