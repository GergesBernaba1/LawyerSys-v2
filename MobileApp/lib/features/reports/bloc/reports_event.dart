abstract class ReportsEvent {}

class LoadFinancialReport extends ReportsEvent {
  final int year;
  final int month;
  final int? customerId;

  LoadFinancialReport({
    required this.year,
    required this.month,
    this.customerId,
  });
}

class LoadOutstandingBalances extends ReportsEvent {}

class LoadCustomerBillingHistory extends ReportsEvent {
  final int customerId;
  LoadCustomerBillingHistory(this.customerId);
}

class RefreshReports extends ReportsEvent {
  final int year;
  final int month;
  final int? customerId;

  RefreshReports({required this.year, required this.month, this.customerId});
}
