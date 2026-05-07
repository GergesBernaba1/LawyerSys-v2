import 'package:qadaya_lawyersys/features/trust-reports/models/trust_report_models.dart';

abstract class TrustReportsState {}

class TrustReportsInitial extends TrustReportsState {}

class TrustReportsLoading extends TrustReportsState {}

class FinancialSummaryLoaded extends TrustReportsState {

  FinancialSummaryLoaded(this.summary, {this.year, this.month});
  final FinancialSummary summary;
  final int? year;
  final int? month;
}

class OutstandingBalancesLoaded extends TrustReportsState {

  OutstandingBalancesLoaded(this.balances);
  final List<OutstandingBalance> balances;
}

class TrustReportsError extends TrustReportsState {

  TrustReportsError(this.message);
  final String message;
}
