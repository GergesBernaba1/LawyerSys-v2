class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netBalance;
  final int totalInvoices;
  final int paidInvoices;
  final int pendingInvoices;
  final double trustBalance;
  final Map<String, dynamic> extras;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalInvoices,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.trustBalance,
    required this.extras,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    final knownKeys = {
      'totalRevenue',
      'totalExpenses',
      'netBalance',
      'totalInvoices',
      'paidInvoices',
      'pendingInvoices',
      'trustBalance',
    };
    final extras = Map<String, dynamic>.fromEntries(
      json.entries.where((e) => !knownKeys.contains(e.key)),
    );

    return FinancialSummary(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0.0,
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      paidInvoices: (json['paidInvoices'] as num?)?.toInt() ?? 0,
      pendingInvoices: (json['pendingInvoices'] as num?)?.toInt() ?? 0,
      trustBalance: (json['trustBalance'] as num?)?.toDouble() ?? 0.0,
      extras: extras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netBalance': netBalance,
      'totalInvoices': totalInvoices,
      'paidInvoices': paidInvoices,
      'pendingInvoices': pendingInvoices,
      'trustBalance': trustBalance,
      ...extras,
    };
  }
}

class OutstandingBalance {
  final String customerName;
  final int customerId;
  final double amount;
  final int invoiceCount;

  OutstandingBalance({
    required this.customerName,
    required this.customerId,
    required this.amount,
    required this.invoiceCount,
  });

  factory OutstandingBalance.fromJson(Map<String, dynamic> json) {
    return OutstandingBalance(
      customerName: json['customerName'] as String? ?? '',
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerId': customerId,
      'amount': amount,
      'invoiceCount': invoiceCount,
    };
  }
}
