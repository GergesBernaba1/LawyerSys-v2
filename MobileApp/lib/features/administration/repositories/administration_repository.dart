import '../../../core/api/api_client.dart';
import '../models/admin_overview.dart';

class AdministrationRepository {
  final ApiClient apiClient;

  AdministrationRepository(this.apiClient);

  Future<AdminOverview> getOverview() async {
    final response = await apiClient.get('/Administration/overview');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AdminOverview.fromJson(data);
    }
    return AdminOverview.fromJson(const {});
  }
}
