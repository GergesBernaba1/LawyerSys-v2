abstract class CustomersEvent {}

class LoadCustomers extends CustomersEvent {}

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
