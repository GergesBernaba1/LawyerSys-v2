class TrustTransactionModel {

  TrustTransactionModel({
    required this.transactionId,
    required this.caseId,
    required this.accountId,
    required this.date,
    required this.transactionType,
    required this.amount,
    required this.status,
    required this.notes,
  });

  factory TrustTransactionModel.fromJson(Map<String, dynamic> json) => TrustTransactionModel(
        transactionId: json['transactionId']?.toString() ?? '',
        caseId: json['caseId']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
        transactionType: json['transactionType']?.toString() ?? '',
        amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        status: json['status']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
  final String transactionId;
  final String caseId;
  final String accountId;
  final DateTime date;
  final String transactionType;
  final double amount;
  final String status;
  final String notes;

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'caseId': caseId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'transactionType': transactionType,
        'amount': amount,
        'status': status,
        'notes': notes,
      };
}
