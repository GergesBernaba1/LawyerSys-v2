import '../models/report.dart';

abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final FinancialReport? financialReport;
  final List<OutstandingBalance> outstandingBalances;
  final CustomerBillingHistory? customerBillingHistory;
  final int year;
  final int month;
  final int? customerId;

  ReportsLoaded({
    this.financialReport,
    this.outstandingBalances = const [],
    this.customerBillingHistory,
    required this.year,
    required this.month,
    this.customerId,
  });

  ReportsLoaded copyWith({
    FinancialReport? financialReport,
    List<OutstandingBalance>? outstandingBalances,
    CustomerBillingHistory? customerBillingHistory,
    int? year,
    int? month,
    int? customerId,
  }) =>
      ReportsLoaded(
        financialReport: financialReport ?? this.financialReport,
        outstandingBalances: outstandingBalances ?? this.outstandingBalances,
        customerBillingHistory:
            customerBillingHistory ?? this.customerBillingHistory,
        year: year ?? this.year,
        month: month ?? this.month,
        customerId: customerId ?? this.customerId,
      );
}

class ReportsError extends ReportsState {
  final String message;
  ReportsError(this.message);
}
