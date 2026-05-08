import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/billing/models/billing.dart';

class BillingRepository {

  BillingRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<BillingPay>> getPayments() async {
    final response = await apiClient.get('/Billing/payments');
    final paymentsData = normalizeJsonList(response.data);
    return paymentsData
        .whereType<Map<String, dynamic>>()
        .map(BillingPay.fromJson)
        .toList();
  }

  Future<List<BillingReceipt>> getReceipts() async {
    final response = await apiClient.get('/Billing/receipts');
    final receiptsData = normalizeJsonList(response.data);
    return receiptsData
        .whereType<Map<String, dynamic>>()
        .map(BillingReceipt.fromJson)
        .toList();
  }

  Future<List<CustomerItem>> getCustomers() async {
    final response = await apiClient.get('/Customers');
    final customersData = normalizeJsonList(response.data);
    return customersData
        .whereType<Map<String, dynamic>>()
        .map(CustomerItem.fromJson)
        .toList();
  }

  Future<List<EmployeeItem>> getEmployees() async {
    final response = await apiClient.get('/Employees');
    final employeesData = normalizeJsonList(response.data);
    return employeesData
        .whereType<Map<String, dynamic>>()
        .map(EmployeeItem.fromJson)
        .toList();
  }

  Future<BillingSummary> getSummary() async {
    final response = await apiClient.get('/Billing/summary');
    return BillingSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> createPayment(BillingPay payment) async {
    await apiClient.post('/Billing/payments', data: payment.toJson());
  }

  Future<void> createReceipt(BillingReceipt receipt) async {
    await apiClient.post('/Billing/receipts', data: receipt.toJson());
  }

  Future<void> deletePayment(int id) async {
    await apiClient.delete('/Billing/payments/$id');
  }

  Future<void> updatePayment(BillingPay payment) async {
    await apiClient.put('/Billing/payments/${payment.id}', data: payment.toJson());
  }

  Future<void> updateReceipt(BillingReceipt receipt) async {
    await apiClient.put('/Billing/receipts/${receipt.id}', data: receipt.toJson());
  }

  Future<void> deleteReceipt(int id) async {
    await apiClient.delete('/Billing/receipts/$id');
  }
}
