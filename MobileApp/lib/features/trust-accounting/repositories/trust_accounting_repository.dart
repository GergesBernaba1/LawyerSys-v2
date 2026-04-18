import '../../../core/api/api_client.dart';
import '../../../core/utils/json_utils.dart';
import '../models/trust_transaction.dart';

class TrustAccountingRepository {
  final ApiClient apiClient;

  TrustAccountingRepository(this.apiClient);

  Future<List<TrustTransactionModel>> getTransactions(
      {int page = 1, int pageSize = 50}) async {
    final response =
        await apiClient.get('/api/trust-transactions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => TrustTransactionModel.fromJson(
            Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<TrustTransactionModel?> getTransactionById(
      String transactionId) async {
    final response =
        await apiClient.get('/api/trust-transactions/$transactionId');
    if (response.data == null) return null;
    return TrustTransactionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<TrustTransactionModel> createTransaction(
      TrustTransactionModel transaction) async {
    final response = await apiClient.post('/api/trust-transactions',
        data: transaction.toJson());
    return TrustTransactionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<TrustTransactionModel> updateTransaction(
      TrustTransactionModel transaction) async {
    final response = await apiClient.put(
        '/api/trust-transactions/${transaction.transactionId}',
        data: transaction.toJson());
    return TrustTransactionModel.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteTransaction(String transactionId) async {
    await apiClient.delete('/api/trust-transactions/$transactionId');
  }

  Future<List<TrustTransactionModel>> searchTransactions(String query) async {
    final response = await apiClient
        .get('/api/trust-transactions/search', queryParameters: {'q': query});
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => TrustTransactionModel.fromJson(
            Map<String, dynamic>.from(raw as Map)))
        .toList();
  }
}
