abstract class TrustReportsEvent {}

class LoadFinancialSummary extends TrustReportsEvent {

  LoadFinancialSummary({this.year, this.month});
  final int? year;
  final int? month;
}

class LoadOutstandingBalances extends TrustReportsEvent {}

class RefreshTrustReports extends TrustReportsEvent {}
