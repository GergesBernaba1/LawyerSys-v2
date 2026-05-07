import 'package:qadaya_lawyersys/core/api/api_client.dart';

class TenantSelection {

  const TenantSelection({
    required this.currentTenantId,
    required this.isSuperAdmin,
    required this.items,
  });
  final int? currentTenantId;
  final bool isSuperAdmin;
  final List<Map<String, dynamic>> items;
}

class TenantsRepository {

  TenantsRepository(this.apiClient);
  final ApiClient apiClient;

  Future<TenantSelection> getAvailableTenants() async {
    final response = await apiClient.get('/tenants/available');
    final data = Map<String, dynamic>.from(response.data as Map);

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];

    return TenantSelection(
      currentTenantId: data['currentTenantId'] is int
          ? data['currentTenantId'] as int
          : int.tryParse((data['currentTenantId'] ?? '').toString()),
      isSuperAdmin: data['isSuperAdmin'] == true,
      items: items,
    );
  }

  Future<void> updateTenantStatus(int id, {required bool isActive}) async {
    await apiClient.put('/tenants/$id/status', data: {'isActive': isActive});
  }

  Future<void> createTenant(Map<String, dynamic> data) async {
    await apiClient.post('/tenants', data: data);
  }

  Future<void> updateTenant(int id, Map<String, dynamic> data) async {
    await apiClient.put('/tenants/$id', data: data);
  }

  Future<void> deleteTenant(int id) async {
    await apiClient.delete('/tenants/$id');
  }
}
