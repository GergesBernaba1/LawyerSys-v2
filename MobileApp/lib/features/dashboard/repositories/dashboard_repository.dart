import 'dart:convert';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/dashboard/models/dashboard_summary.dart';

class DashboardRepository {

  DashboardRepository(this.apiClient, this.localDatabase);
  final ApiClient apiClient;
  final LocalDatabase localDatabase;

  Future<DashboardSummary> getSummary({String? tenantId}) async {
    try {
      final response = await apiClient.get(ApiConstants.dashboard);
      final summary = DashboardSummary.fromJson(Map<String, dynamic>.from(response.data as Map));

      await localDatabase.upsertDashboard('default', summary.toJson(), tenantId: tenantId);
      return summary;
    } catch (e) {
      final rows = await localDatabase.getDashboard('default', tenantId: tenantId);
      if (rows.isNotEmpty) {
        return DashboardSummary.fromJson(Map<String, dynamic>.from(jsonDecode(rows.first['data'] as String) as Map));
      }
      rethrow;
    }
  }
}


