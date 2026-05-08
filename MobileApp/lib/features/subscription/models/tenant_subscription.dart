class BillingTransaction {
  const BillingTransaction({
    required this.id,
    required this.packageName,
    required this.billingCycle,
    required this.status,
    required this.amount,
    required this.currency,
    this.dueDateUtc,
    this.paidAtUtc,
    this.reference,
    this.notes,
  });

  factory BillingTransaction.fromJson(Map<String, dynamic> json) {
    return BillingTransaction(
      id: json['id'] as int? ?? 0,
      packageName: json['packageName'] as String? ?? '',
      billingCycle: json['billingCycle'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '',
      dueDateUtc: json['dueDateUtc'] != null
          ? DateTime.tryParse(json['dueDateUtc'] as String)
          : null,
      paidAtUtc: json['paidAtUtc'] != null
          ? DateTime.tryParse(json['paidAtUtc'] as String)
          : null,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final int id;
  final String packageName;
  final String billingCycle;
  final String status;
  final double amount;
  final String currency;
  final DateTime? dueDateUtc;
  final DateTime? paidAtUtc;
  final String? reference;
  final String? notes;
}

class TenantSubscription {
  const TenantSubscription({
    required this.status,
    required this.packageName,
    required this.billingCycle,
    required this.officeSize,
    this.price,
    this.currency,
    this.features = const [],
    this.startDateUtc,
    this.endDateUtc,
    this.nextBillingDateUtc,
    this.transactions = const [],
  });

  factory TenantSubscription.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['packageFeatures'];
    final List<String> features;
    if (rawFeatures is List) {
      features = rawFeatures.map((f) => f.toString()).toList();
    } else {
      features = const [];
    }

    final rawTx = json['transactions'];
    final List<BillingTransaction> transactions;
    if (rawTx is List) {
      transactions = rawTx
          .whereType<Map<String, dynamic>>()
          .map(BillingTransaction.fromJson)
          .toList();
    } else {
      transactions = const [];
    }

    return TenantSubscription(
      status: json['status'] as String? ?? '',
      packageName: json['packageName'] as String? ?? '',
      billingCycle: json['billingCycle'] as String? ?? '',
      officeSize: json['officeSize'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      features: features,
      startDateUtc: json['startDateUtc'] != null
          ? DateTime.tryParse(json['startDateUtc'] as String)
          : null,
      endDateUtc: json['endDateUtc'] != null
          ? DateTime.tryParse(json['endDateUtc'] as String)
          : null,
      nextBillingDateUtc: json['nextBillingDateUtc'] != null
          ? DateTime.tryParse(json['nextBillingDateUtc'] as String)
          : null,
      transactions: transactions,
    );
  }

  final String status;
  final String packageName;
  final String billingCycle;
  final String officeSize;
  final double? price;
  final String? currency;
  final List<String> features;
  final DateTime? startDateUtc;
  final DateTime? endDateUtc;
  final DateTime? nextBillingDateUtc;
  final List<BillingTransaction> transactions;
}
