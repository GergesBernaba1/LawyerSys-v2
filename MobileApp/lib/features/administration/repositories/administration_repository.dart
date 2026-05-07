import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/administration/models/admin_overview.dart';

class AdministrationRepository {

  AdministrationRepository(this.apiClient);
  final ApiClient apiClient;

  Future<AdminOverview> getOverview() async {
    final response = await apiClient.get('/Administration/overview');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AdminOverview.fromJson(data);
    }
    return AdminOverview.fromJson(const {});
  }
}
