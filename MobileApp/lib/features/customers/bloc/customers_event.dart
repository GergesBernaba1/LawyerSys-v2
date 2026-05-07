abstract class CustomersEvent {}

class LoadCustomers extends CustomersEvent {}

class LoadMoreCustomers extends CustomersEvent {}

class SearchCustomers extends CustomersEvent {
  SearchCustomers(this.query);
  final String query;
}

class RefreshCustomers extends CustomersEvent {}

class SelectCustomer extends CustomersEvent {
  SelectCustomer(this.customerId);
  final String customerId;
}

class LoadCustomerDetail extends CustomersEvent {
  LoadCustomerDetail(this.customerId);
  final String customerId;
}

class CreateCustomer extends CustomersEvent {
  CreateCustomer(this.data);
  final Map<String, dynamic> data;
}

class UpdateCustomer extends CustomersEvent {
  UpdateCustomer(this.customerId, this.data);
  final String customerId;
  final Map<String, dynamic> data;
}

class DeleteCustomer extends CustomersEvent {
  DeleteCustomer(this.customerId);
  final String customerId;
}

// Case Notification Preferences
class LoadCaseNotificationPreference extends CustomersEvent {
  LoadCaseNotificationPreference(this.caseCode);
  final int caseCode;
}

class UpdateCaseNotificationPreference extends CustomersEvent {
  UpdateCaseNotificationPreference(this.caseCode, {required this.notificationsEnabled});
  final int caseCode;
  final bool notificationsEnabled;
}

// Payment Proofs
class SubmitPaymentProof extends CustomersEvent {
  
  SubmitPaymentProof({
    required this.caseCode,
    required this.amount,
    required this.paymentDate,
    required this.filePath,
    this.notes,
  });
  final int caseCode;
  final double amount;
  final DateTime paymentDate;
  final String filePath;
  final String? notes;
}

// Requested Documents
class LoadRequestedDocuments extends CustomersEvent {
  LoadRequestedDocuments(this.caseCode);
  final int caseCode;
}

class SubmitRequestedDocument extends CustomersEvent {
  
  SubmitRequestedDocument({
    required this.caseCode,
    required this.requestId,
    required this.filePath,
    this.notes,
  });
  final int caseCode;
  final int requestId;
  final String filePath;
  final String? notes;
}

