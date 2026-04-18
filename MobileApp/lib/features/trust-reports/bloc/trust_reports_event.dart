abstract class TrustReportsEvent {}

class LoadFinancialSummary extends TrustReportsEvent {
  final int? year;
  final int? month;

  LoadFinancialSummary({this.year, this.month});
}

class LoadOutstandingBalances extends TrustReportsEvent {}

class RefreshTrustReports extends TrustReportsEvent {}
