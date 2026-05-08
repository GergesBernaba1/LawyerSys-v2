import 'package:qadaya_lawyersys/features/billing/models/billing.dart';

abstract class BillingEvent {}

class LoadPayments extends BillingEvent {}

class LoadReceipts extends BillingEvent {}

class LoadCustomers extends BillingEvent {}

class LoadEmployees extends BillingEvent {}

class LoadSummary extends BillingEvent {}

class CreatePayment extends BillingEvent {

  CreatePayment(this.payment);
  final BillingPay payment;
}

class CreateReceipt extends BillingEvent {

  CreateReceipt(this.receipt);
  final BillingReceipt receipt;
}

class DeletePayment extends BillingEvent {

  DeletePayment(this.id);
  final int id;
}

class DeleteReceipt extends BillingEvent {

  DeleteReceipt(this.id);
  final int id;
}

class UpdatePayment extends BillingEvent {

  UpdatePayment(this.payment);
  final BillingPay payment;
}

class UpdateReceipt extends BillingEvent {

  UpdateReceipt(this.receipt);
  final BillingReceipt receipt;
}
