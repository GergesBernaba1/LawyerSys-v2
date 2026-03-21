import '../../../core/api/api_client.dart';
import '../models/billing.dart';

class BillingRepository {
  final ApiClient apiClient;

  BillingRepository(this.apiClient);

  Future<List<BillingPay>> getPayments() async {
    final response = await apiClient.get('/Billing/payments');
    final paymentsData = response.data as List<dynamic>? ?? [];
    return paymentsData.map((json) => BillingPay.fromJson(json)).toList();
  }

  Future<List<BillingReceipt>> getReceipts() async {
    final response = await apiClient.get('/Billing/receipts');
    final receiptsData = response.data as List<dynamic>? ?? [];
    return receiptsData.map((json) => BillingReceipt.fromJson(json)).toList();
  }

  Future<List<CustomerItem>> getCustomers() async {
    final response = await apiClient.get('/Customers');
    final customersData = response.data as List<dynamic>? ?? [];
    return customersData.map((json) => CustomerItem.fromJson(json)).toList();
  }

  Future<List<EmployeeItem>> getEmployees() async {
    final response = await apiClient.get('/Employees');
    final employeesData = response.data as List<dynamic>? ?? [];
    return employeesData.map((json) => EmployeeItem.fromJson(json)).toList();
  }

  Future<BillingSummary> getSummary() async {
    final response = await apiClient.get('/Billing/summary');
    return BillingSummary.fromJson(response.data);
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

  Future<void> deleteReceipt(int id) async {
    await apiClient.delete('/Billing/receipts/$id');
  }
}