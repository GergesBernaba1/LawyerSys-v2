import '../models/trust_report_models.dart';

abstract class TrustReportsState {}

class TrustReportsInitial extends TrustReportsState {}

class TrustReportsLoading extends TrustReportsState {}

class FinancialSummaryLoaded extends TrustReportsState {
  final FinancialSummary summary;
  final int? year;
  final int? month;

  FinancialSummaryLoaded(this.summary, {this.year, this.month});
}

class OutstandingBalancesLoaded extends TrustReportsState {
  final List<OutstandingBalance> balances;

  OutstandingBalancesLoaded(this.balances);
}

class TrustReportsError extends TrustReportsState {
  final String message;

  TrustReportsError(this.message);
}
