import 'package:qadaya_lawyersys/features/customers/models/case_notification_preference.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer_payment_proof.dart';
import 'package:qadaya_lawyersys/features/customers/models/customer_requested_document.dart';

abstract class CustomersState {}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersLoaded extends CustomersState {
  
  CustomersLoaded(
    this.customers, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });
  final List<Customer> customers;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

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
  CustomersError(this.message);
  final String message;
}

class CustomerDetailLoaded extends CustomersState {
  CustomerDetailLoaded(this.customer);
  final Customer customer;
}

class CustomerOperationSuccess extends CustomersState {
  CustomerOperationSuccess(this.message, {this.customerId});
  final String message;
  /// ID of the created/updated customer; non-null after create so callers
  /// can follow-up with image uploads or navigation.
  final String? customerId;
}

// Case Notification Preference States
class CaseNotificationPreferenceLoaded extends CustomersState {
  CaseNotificationPreferenceLoaded(this.preference);
  final CaseNotificationPreference preference;
}

class CaseNotificationPreferenceUpdated extends CustomersState {
  CaseNotificationPreferenceUpdated(this.preference);
  final CaseNotificationPreference preference;
}

// Payment Proof States
class PaymentProofSubmitting extends CustomersState {}

class PaymentProofSubmitted extends CustomersState {
  PaymentProofSubmitted(this.proof);
  final CustomerPaymentProof proof;
}

// Requested Documents States
class RequestedDocumentsLoaded extends CustomersState {
  RequestedDocumentsLoaded(this.documents);
  final List<CustomerRequestedDocument> documents;
}

class RequestedDocumentSubmitting extends CustomersState {}

class RequestedDocumentSubmitted extends CustomersState {
  RequestedDocumentSubmitted(this.document);
  final CustomerRequestedDocument document;
}


