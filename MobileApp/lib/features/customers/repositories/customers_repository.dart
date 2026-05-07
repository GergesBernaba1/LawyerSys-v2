import 'package:dio/dio.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';
import 'package:qadaya_lawyersys/features/customers/models/case_notification_preference.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer_payment_proof.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer_requested_document.dart';

class CustomersRepository {

  CustomersRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<Customer>> getCustomers({int page = 1, int pageSize = 50}) async {
    final response = await apiClient.get('/api/customers', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    },);

    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<Customer?> getCustomerById(String customerId) async {
    final response = await apiClient.get('/api/customers/$customerId');
    if (response.data == null) return null;
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final response = await apiClient
        .get('/api/customers/search', queryParameters: {'q': query});
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) => Customer.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await apiClient.post('/api/customers', data: data);
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Customer> updateCustomer(String customerId, Map<String, dynamic> data) async {
    final response = await apiClient.put('/api/customers/$customerId', data: data);
    return Customer.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCustomer(String customerId) async {
    await apiClient.delete('/api/customers/$customerId');
  }

  Future<void> uploadProfileImage(String customerId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    await apiClient.post('/customers/$customerId/profile-image', data: formData);
  }

  // Case Notification Preferences
  Future<CaseNotificationPreference> getCaseNotificationPreference(
      int caseCode,) async {
    final response = await apiClient
        .get('/api/cases/$caseCode/notification-preferences');
    return CaseNotificationPreference.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  Future<CaseNotificationPreference> updateCaseNotificationPreference(
      int caseCode, bool notificationsEnabled,) async {
    final response = await apiClient.put(
      '/api/cases/$caseCode/notification-preferences',
      data: {'notificationsEnabled': notificationsEnabled},
    );
    return CaseNotificationPreference.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  // Payment Proofs
  Future<CustomerPaymentProof> submitPaymentProof({
    required int caseCode,
    required double amount,
    required DateTime paymentDate,
    required String filePath,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String().split('T')[0],
      'notes': notes ?? '',
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await apiClient.post(
      '/api/client-portal/cases/$caseCode/payment-proofs',
      data: formData,
    );
    return CustomerPaymentProof.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }

  // Requested Documents
  Future<List<CustomerRequestedDocument>> getRequestedDocuments(
      int caseCode,) async {
    // This would typically come from the client portal endpoint
    // For now, we'll assume it's part of the case detail
    final response = await apiClient
        .get('/api/client-portal/cases/$caseCode/requested-documents');
    final data = normalizeJsonList(response.data);
    if (data.isEmpty) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((raw) =>
            CustomerRequestedDocument.fromJson(Map<String, dynamic>.from(raw as Map)),)
        .toList();
  }

  Future<CustomerRequestedDocument> submitRequestedDocument({
    required int caseCode,
    required int requestId,
    required String filePath,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'notes': notes ?? '',
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await apiClient.post(
      '/api/client-portal/cases/$caseCode/requested-documents/$requestId/submit',
      data: formData,
    );
    return CustomerRequestedDocument.fromJson(
        Map<String, dynamic>.from(response.data as Map),);
  }
}
