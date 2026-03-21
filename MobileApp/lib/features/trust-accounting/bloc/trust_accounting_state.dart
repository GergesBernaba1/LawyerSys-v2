import '../models/trust_transaction.dart';

abstract class TrustAccountingState {}

class TrustAccountingInitial extends TrustAccountingState {}
class TrustAccountingLoading extends TrustAccountingState {}

class TrustAccountingLoaded extends TrustAccountingState {
  final List<TrustTransactionModel> transactions;
  TrustAccountingLoaded(this.transactions);
}

class TrustAccountingError extends TrustAccountingState {
  final String message;
  TrustAccountingError(this.message);
}

class TrustTransactionDetailLoaded extends TrustAccountingState {
  final TrustTransactionModel transaction;
  TrustTransactionDetailLoaded(this.transaction);
}

class TrustTransactionOperationSuccess extends TrustAccountingState {
  final String message;
  TrustTransactionOperationSuccess(this.message);
}
