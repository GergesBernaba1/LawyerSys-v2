import 'package:qadaya_lawyersys/features/trust-accounting/models/trust_transaction.dart';

abstract class TrustAccountingEvent {}

class LoadTrustTransactions extends TrustAccountingEvent {}
class RefreshTrustTransactions extends TrustAccountingEvent {}

class SearchTrustTransactions extends TrustAccountingEvent {
  SearchTrustTransactions(this.query);
  final String query;
}

class SelectTrustTransaction extends TrustAccountingEvent {
  SelectTrustTransaction(this.transactionId);
  final String transactionId;
}

class CreateTrustTransaction extends TrustAccountingEvent {
  CreateTrustTransaction(this.transaction);
  final TrustTransactionModel transaction;
}

class UpdateTrustTransaction extends TrustAccountingEvent {
  UpdateTrustTransaction(this.transaction);
  final TrustTransactionModel transaction;
}

class DeleteTrustTransaction extends TrustAccountingEvent {
  DeleteTrustTransaction(this.transactionId);
  final String transactionId;
}

class LoadTrustLedger extends TrustAccountingEvent {
  LoadTrustLedger(this.customerId);
  final int customerId;
}
