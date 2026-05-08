import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/trust-accounting/models/trust_transaction.dart';

class TrustAccountingRepository {

  TrustAccountingRepository(this.apiClient);
  final ApiClient apiClient;

  // Returns trust accounts (customer balances).
  Future<List<TrustTransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await apiClient.get('/api/TrustAccounting/accounts');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => TrustTransactionModel.fromAccountJson(
            Map<String, dynamic>.from(raw),),)
        .toList();
  }

  // Returns ledger entries for a specific customer.
  Future<List<TrustTransactionModel>> getLedger(int customerId) async {
    final response = await apiClient
        .get('/api/TrustAccounting/accounts/$customerId/ledger');
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => TrustTransactionModel.fromLedgerJson(
            Map<String, dynamic>.from(raw),),)
        .toList();
  }

  Future<TrustTransactionModel?> getTransactionById(
      String transactionId,) async {
    return null; // No direct by-ID endpoint on this backend
  }

  // Creates a deposit, withdrawal, or adjustment based on transactionType.
  Future<TrustTransactionModel> createTransaction(
      TrustTransactionModel transaction,) async {
    final String endpoint;
    switch (transaction.transactionType.toLowerCase()) {
      case 'deposit':
        endpoint = '/api/TrustAccounting/deposits';
      case 'withdrawal':
        endpoint = '/api/TrustAccounting/withdrawals';
      default:
        endpoint = '/api/TrustAccounting/adjustments';
    }
    final response = await apiClient.post(endpoint, data: transaction.toJson());
    return TrustTransactionModel.fromLedgerJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<TrustTransactionModel> updateTransaction(
      TrustTransactionModel transaction,) async {
    // No generic update endpoint; return unchanged
    return transaction;
  }

  Future<void> deleteTransaction(String transactionId) async {
    // No DELETE endpoint on TrustAccounting controller
  }

  Future<List<TrustTransactionModel>> searchTransactions(String query) async {
    final response = await apiClient.get('/api/TrustAccounting/accounts',
        queryParameters: {'search': query},);
    final data = normalizeJsonList(response.data);
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => TrustTransactionModel.fromAccountJson(
            Map<String, dynamic>.from(raw),),)
        .toList();
  }
}
