abstract class CustomersEvent {}

class LoadCustomers extends CustomersEvent {}

class LoadMoreCustomers extends CustomersEvent {}

class SearchCustomers extends CustomersEvent {
  final String query;
  SearchCustomers(this.query);
}

class RefreshCustomers extends CustomersEvent {}

class SelectCustomer extends CustomersEvent {
  final String customerId;
  SelectCustomer(this.customerId);
}

class LoadCustomerDetail extends CustomersEvent {
  final String customerId;
  LoadCustomerDetail(this.customerId);
}

class CreateCustomer extends CustomersEvent {
  final Map<String, dynamic> data;
  CreateCustomer(this.data);
}

class UpdateCustomer extends CustomersEvent {
  final String customerId;
  final Map<String, dynamic> data;
  UpdateCustomer(this.customerId, this.data);
}

class DeleteCustomer extends CustomersEvent {
  final String customerId;
  DeleteCustomer(this.customerId);
}

// Case Notification Preferences
class LoadCaseNotificationPreference extends CustomersEvent {
  final int caseCode;
  LoadCaseNotificationPreference(this.caseCode);
}

class UpdateCaseNotificationPreference extends CustomersEvent {
  final int caseCode;
  final bool notificationsEnabled;
  UpdateCaseNotificationPreference(this.caseCode, this.notificationsEnabled);
}

// Payment Proofs
class SubmitPaymentProof extends CustomersEvent {
  final int caseCode;
  final double amount;
  final DateTime paymentDate;
  final String filePath;
  final String? notes;
  
  SubmitPaymentProof({
    required this.caseCode,
    required this.amount,
    required this.paymentDate,
    required this.filePath,
    this.notes,
  });
}

// Requested Documents
class LoadRequestedDocuments extends CustomersEvent {
  final int caseCode;
  LoadRequestedDocuments(this.caseCode);
}

class SubmitRequestedDocument extends CustomersEvent {
  final int caseCode;
  final int requestId;
  final String filePath;
  final String? notes;
  
  SubmitRequestedDocument({
    required this.caseCode,
    required this.requestId,
    required this.filePath,
    this.notes,
  });
}

