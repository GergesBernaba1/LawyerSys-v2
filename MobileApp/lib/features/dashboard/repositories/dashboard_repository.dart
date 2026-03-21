import 'dart:convert';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/storage/local_database.dart';
import '../dashboard/models/dashboard_summary.dart';

class DashboardRepository {
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  DashboardRepository(this.apiClient, this.localDatabase);

  Future<DashboardSummary> getSummary({String? tenantId}) async {
    try {
      final response = await apiClient.get(ApiConstants.dashboard);
      final summary = DashboardSummary.fromJson(Map<String, dynamic>.from(response.data));

      await localDatabase.upsertDashboard('default', summary.toJson(), tenantId: tenantId);
      return summary;
    } catch (e) {
      final rows = await localDatabase.getDashboard('default', tenantId: tenantId);
      if (rows.isNotEmpty) {
        return DashboardSummary.fromJson(Map<String, dynamic>.from(jsonDecode(rows.first['data'] as String)));
      }
      rethrow;
    }
  }
}

