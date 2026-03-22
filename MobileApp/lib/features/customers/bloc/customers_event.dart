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
