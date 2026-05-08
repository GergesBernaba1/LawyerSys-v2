abstract class ReportsEvent {}

class LoadFinancialReport extends ReportsEvent {

  LoadFinancialReport({
    required this.year,
    required this.month,
    this.customerId,
  });
  final int year;
  final int month;
  final int? customerId;
}

class LoadOutstandingBalances extends ReportsEvent {}

class LoadCustomerBillingHistory extends ReportsEvent {
  LoadCustomerBillingHistory(this.customerId);
  final int customerId;
}

class RefreshReports extends ReportsEvent {

  RefreshReports({required this.year, required this.month, this.customerId});
  final int year;
  final int month;
  final int? customerId;
}

class ExportFinancialReport extends ReportsEvent {

  ExportFinancialReport({
    required this.year,
    required this.month,
    required this.format,
  });
  final int year;
  final int month;
  final String format;
}
