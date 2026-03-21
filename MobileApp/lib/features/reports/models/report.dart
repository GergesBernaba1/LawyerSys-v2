class MonthlyCashFlowPoint {
  final int year;
  final int month;
  final double payments;
  final double receipts;
  final double netCashFlow;

  MonthlyCashFlowPoint({
    required this.year,
    required this.month,
    required this.payments,
    required this.receipts,
    required this.netCashFlow,
  });

  factory MonthlyCashFlowPoint.fromJson(Map<String, dynamic> json) =>
      MonthlyCashFlowPoint(
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        payments: (json['payments'] as num?)?.toDouble() ?? 0,
        receipts: (json['receipts'] as num?)?.toDouble() ?? 0,
        netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0,
      );

  String get label =>
      '$year-${month.toString().padLeft(2, '0')}';
}

class FinancialSummary {
  final int year;
  final int month;
  final double totalPayments;
  final double totalReceipts;
  final double netCashFlow;
  final int paymentsCount;
  final int receiptsCount;

  FinancialSummary({
    required this.year,
    required this.month,
    required this.totalPayments,
    required this.totalReceipts,
    required this.netCashFlow,
    required this.paymentsCount,
    required this.receiptsCount,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      FinancialSummary(
        year: json['year'] as int? ?? 0,
        month: json['month'] as int? ?? 0,
        totalPayments: (json['totalPayments'] as num?)?.toDouble() ?? 0,
        totalReceipts: (json['totalReceipts'] as num?)?.toDouble() ?? 0,
        netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0,
        paymentsCount: json['paymentsCount'] as int? ?? 0,
        receiptsCount: json['receiptsCount'] as int? ?? 0,
      );
}

class FinancialReport {
  final FinancialSummary summary;
  final List<MonthlyCashFlowPoint> last6Months;

  FinancialReport({required this.summary, required this.last6Months});

  factory FinancialReport.fromJson(Map<String, dynamic> json) =>
      FinancialReport(
        summary: FinancialSummary.fromJson(
            Map<String, dynamic>.from(json['summary'] as Map)),
        last6Months: (json['last6Months'] as List<dynamic>? ?? [])
            .map((e) => MonthlyCashFlowPoint.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class OutstandingBalance {
  final int customerId;
  final String customerName;
  final double casesTotalAmount;
  final double paidAmount;
  final double outstandingBalance;

  OutstandingBalance({
    required this.customerId,
    required this.customerName,
    required this.casesTotalAmount,
    required this.paidAmount,
    required this.outstandingBalance,
  });

  factory OutstandingBalance.fromJson(Map<String, dynamic> json) =>
      OutstandingBalance(
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName']?.toString() ?? '',
        casesTotalAmount: (json['casesTotalAmount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        outstandingBalance:
            (json['outstandingBalance'] as num?)?.toDouble() ?? 0,
      );
}

class BillingHistoryEntry {
  final String type;
  final int id;
  final String? date;
  final double amount;
  final String? notes;

  BillingHistoryEntry({
    required this.type,
    required this.id,
    this.date,
    required this.amount,
    this.notes,
  });

  factory BillingHistoryEntry.fromJson(Map<String, dynamic> json) =>
      BillingHistoryEntry(
        type: json['type']?.toString() ?? '',
        id: json['id'] as int? ?? 0,
        date: json['date']?.toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        notes: json['notes']?.toString(),
      );
}

class CustomerBillingHistory {
  final int customerId;
  final String customerName;
  final double totalPayments;
  final List<BillingHistoryEntry> entries;

  CustomerBillingHistory({
    required this.customerId,
    required this.customerName,
    required this.totalPayments,
    required this.entries,
  });

  factory CustomerBillingHistory.fromJson(Map<String, dynamic> json) =>
      CustomerBillingHistory(
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName']?.toString() ?? '',
        totalPayments: (json['totalPayments'] as num?)?.toDouble() ?? 0,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => BillingHistoryEntry.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
