import '../../../core/api/api_client.dart';
import '../models/report.dart';

class ReportsRepository {
  final ApiClient apiClient;

  ReportsRepository(this.apiClient);

  Future<FinancialReport> getFinancialSummary({
    required int year,
    required int month,
    int? customerId,
  }) async {
    final params = <String, dynamic>{'year': year, 'month': month};
    if (customerId != null) params['customerId'] = customerId;

    final response = await apiClient.get(
      '/api/Reports/financial-summary',
      queryParameters: params,
    );
    return FinancialReport.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<OutstandingBalance>> getOutstandingBalances() async {
    final response =
        await apiClient.get('/api/Reports/outstanding-balances');
    return (response.data as List<dynamic>? ?? [])
        .map((e) => OutstandingBalance.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CustomerBillingHistory> getCustomerBillingHistory(
      int customerId) async {
    final response = await apiClient
        .get('/api/Reports/customers/$customerId/billing-history');
    return CustomerBillingHistory.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }
}
