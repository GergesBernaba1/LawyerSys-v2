import '../models/customer.dart';
import '../models/case_notification_preference.dart';
import '../models/customer_payment_proof.dart';
import '../models/customer_requested_document.dart';

abstract class CustomersState {}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersLoaded extends CustomersState {
  final List<Customer> customers;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  
  CustomersLoaded(
    this.customers, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  CustomersLoaded copyWith({
    List<Customer>? customers,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CustomersLoaded(
      customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class CustomersError extends CustomersState {
  final String message;
  CustomersError(this.message);
}

class CustomerDetailLoaded extends CustomersState {
  final Customer customer;
  CustomerDetailLoaded(this.customer);
}

class CustomerOperationSuccess extends CustomersState {
  final String message;
  CustomerOperationSuccess(this.message);
}

// Case Notification Preference States
class CaseNotificationPreferenceLoaded extends CustomersState {
  final CaseNotificationPreference preference;
  CaseNotificationPreferenceLoaded(this.preference);
}

class CaseNotificationPreferenceUpdated extends CustomersState {
  final CaseNotificationPreference preference;
  CaseNotificationPreferenceUpdated(this.preference);
}

// Payment Proof States
class PaymentProofSubmitting extends CustomersState {}

class PaymentProofSubmitted extends CustomersState {
  final CustomerPaymentProof proof;
  PaymentProofSubmitted(this.proof);
}

// Requested Documents States
class RequestedDocumentsLoaded extends CustomersState {
  final List<CustomerRequestedDocument> documents;
  RequestedDocumentsLoaded(this.documents);
}

class RequestedDocumentSubmitting extends CustomersState {}

class RequestedDocumentSubmitted extends CustomersState {
  final CustomerRequestedDocument document;
  RequestedDocumentSubmitted(this.document);
}

