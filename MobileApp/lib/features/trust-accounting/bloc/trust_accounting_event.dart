import '../models/trust_transaction.dart';

abstract class TrustAccountingEvent {}

class LoadTrustTransactions extends TrustAccountingEvent {}
class RefreshTrustTransactions extends TrustAccountingEvent {}

class SearchTrustTransactions extends TrustAccountingEvent {
  final String query;
  SearchTrustTransactions(this.query);
}

class SelectTrustTransaction extends TrustAccountingEvent {
  final String transactionId;
  SelectTrustTransaction(this.transactionId);
}

class CreateTrustTransaction extends TrustAccountingEvent {
  final TrustTransactionModel transaction;
  CreateTrustTransaction(this.transaction);
}

class UpdateTrustTransaction extends TrustAccountingEvent {
  final TrustTransactionModel transaction;
  UpdateTrustTransaction(this.transaction);
}

class DeleteTrustTransaction extends TrustAccountingEvent {
  final String transactionId;
  DeleteTrustTransaction(this.transactionId);
}
