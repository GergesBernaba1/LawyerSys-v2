import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/trust-reports/models/trust_report_models.dart';

class TrustReportsRepository {

  TrustReportsRepository(this.apiClient);
  final ApiClient apiClient;

  Future<FinancialSummary> getFinancialSummary({int? year, int? month}) async {
    final queryParameters = <String, dynamic>{};
    if (year != null) queryParameters['year'] = year;
    if (month != null) queryParameters['month'] = month;

    final response = await apiClient.get(
      '/Reports/financial-summary',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return FinancialSummary.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<List<OutstandingBalance>> getOutstandingBalances() async {
    final response = await apiClient.get('/Reports/outstanding-balances');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OutstandingBalance.fromJson)
        .toList();
  }
}
