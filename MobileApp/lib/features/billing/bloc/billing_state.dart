import '../models/billing.dart';

abstract class BillingState {}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoaded extends BillingState {
  final List<BillingPay> payments;
  final List<BillingReceipt> receipts;
  final List<CustomerItem> customers;
  final List<EmployeeItem> employees;
  final BillingSummary? summary;

  BillingLoaded({
    required this.payments,
    required this.receipts,
    required this.customers,
    required this.employees,
    this.summary,
  });
}

class BillingError extends BillingState {
  final String message;
  BillingError(this.message);
}