import '../../../core/api/api_client.dart';

class TenantSelection {
  final int? currentTenantId;
  final bool isSuperAdmin;
  final List<Map<String, dynamic>> items;

  const TenantSelection({
    required this.currentTenantId,
    required this.isSuperAdmin,
    required this.items,
  });
}

class TenantsRepository {
  final ApiClient apiClient;

  TenantsRepository(this.apiClient);

  Future<TenantSelection> getAvailableTenants() async {
    final response = await apiClient.get('/tenants/available');
    final data = Map<String, dynamic>.from(response.data as Map);

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return TenantSelection(
      currentTenantId: data['currentTenantId'] is int
          ? data['currentTenantId'] as int
          : int.tryParse((data['currentTenantId'] ?? '').toString()),
      isSuperAdmin: data['isSuperAdmin'] == true,
      items: items,
    );
  }

  Future<void> updateTenantStatus(int id, bool isActive) async {
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
