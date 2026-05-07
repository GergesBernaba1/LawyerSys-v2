import 'package:qadaya_lawyersys/features/billing/models/billing.dart';

abstract class BillingState {}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoaded extends BillingState {

  BillingLoaded({
    required this.payments,
    required this.receipts,
    required this.customers,
    required this.employees,
    this.summary,
  });
  final List<BillingPay> payments;
  final List<BillingReceipt> receipts;
  final List<CustomerItem> customers;
  final List<EmployeeItem> employees;
  final BillingSummary? summary;
}

class BillingError extends BillingState {
  BillingError(this.message);
  final String message;
}
