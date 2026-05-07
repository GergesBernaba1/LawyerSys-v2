import '../models/customer.dart';

abstract class CustomersState {}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersLoaded extends CustomersState {
  final List<Customer> customers;
  CustomersLoaded(this.customers);
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
  /// ID of the created/updated customer; non-null after create so callers
  /// can follow-up with image uploads or navigation.
  final String? customerId;
  CustomerOperationSuccess(this.message, {this.customerId});
}
