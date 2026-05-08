import 'package:qadaya_lawyersys/features/trust-accounting/models/trust_transaction.dart';

abstract class TrustAccountingState {}

class TrustAccountingInitial extends TrustAccountingState {}
class TrustAccountingLoading extends TrustAccountingState {}

class TrustAccountingLoaded extends TrustAccountingState {
  TrustAccountingLoaded(this.transactions);
  final List<TrustTransactionModel> transactions;
}

class TrustAccountingError extends TrustAccountingState {
  TrustAccountingError(this.message);
  final String message;
}

class TrustTransactionDetailLoaded extends TrustAccountingState {
  TrustTransactionDetailLoaded(this.transaction);
  final TrustTransactionModel transaction;
}

class TrustTransactionOperationSuccess extends TrustAccountingState {
  TrustTransactionOperationSuccess(this.message);
  final String message;
}

class TrustLedgerLoaded extends TrustAccountingState {
  TrustLedgerLoaded({required this.entries, required this.customerId});
  final List<TrustTransactionModel> entries;
  final int customerId;
}
