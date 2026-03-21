abstract class BillingEvent {}

class LoadPayments extends BillingEvent {}

class LoadReceipts extends BillingEvent {}

class LoadCustomers extends BillingEvent {}

class LoadEmployees extends BillingEvent {}

class LoadSummary extends BillingEvent {}

class CreatePayment extends BillingEvent {
  final BillingPay payment;

  CreatePayment(this.payment);
}

class CreateReceipt extends BillingEvent {
  final BillingReceipt receipt;

  CreateReceipt(this.receipt);
}

class DeletePayment extends BillingEvent {
  final int id;

  DeletePayment(this.id);
}

class DeleteReceipt extends BillingEvent {
  final int id;

  DeleteReceipt(this.id);
}