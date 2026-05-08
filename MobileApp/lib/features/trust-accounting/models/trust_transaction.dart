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
    this.customerName,
    this.runningBalance,
    this.reference,
    this.description,
  });

  factory TrustTransactionModel.fromJson(Map<String, dynamic> json) =>
      TrustTransactionModel(
        transactionId: json['transactionId']?.toString() ?? '',
        caseId: json['caseId']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        transactionType: json['transactionType']?.toString() ?? '',
        amount: (json['amount'] is num)
            ? (json['amount'] as num).toDouble()
            : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        status: json['status']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );

  // Maps the GET /api/TrustAccounting/accounts response.
  factory TrustTransactionModel.fromAccountJson(
      Map<String, dynamic> json,) =>
      TrustTransactionModel(
        transactionId: json['customerId']?.toString() ?? '',
        caseId: '',
        accountId: json['customerId']?.toString() ?? '',
        date: json['lastMovementDate'] != null
            ? DateTime.tryParse(json['lastMovementDate'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        transactionType: 'Account',
        amount: (json['currentBalance'] is num)
            ? (json['currentBalance'] as num).toDouble()
            : double.tryParse(json['currentBalance']?.toString() ?? '0') ??
                0.0,
        status: 'Active',
        notes: '',
        customerName: json['customerName']?.toString(),
        runningBalance: (json['currentBalance'] is num)
            ? (json['currentBalance'] as num).toDouble()
            : null,
      );

  // Maps GET /api/TrustAccounting/accounts/{id}/ledger response.
  factory TrustTransactionModel.fromLedgerJson(
      Map<String, dynamic> json,) =>
      TrustTransactionModel(
        transactionId: json['id']?.toString() ?? '',
        caseId: json['caseCode']?.toString() ?? '',
        accountId: json['customerId']?.toString() ?? '',
        date: json['operationDate'] != null
            ? DateTime.tryParse(json['operationDate'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        transactionType: json['entryType']?.toString() ?? '',
        amount: (json['amount'] is num)
            ? (json['amount'] as num).toDouble()
            : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        status: '',
        notes: json['description']?.toString() ?? '',
        customerName: json['customerName']?.toString(),
        runningBalance: (json['runningBalance'] is num)
            ? (json['runningBalance'] as num).toDouble()
            : null,
        reference: json['reference']?.toString(),
        description: json['description']?.toString(),
      );

  final String transactionId;
  final String caseId;
  final String accountId;
  final DateTime date;
  final String transactionType;
  final double amount;
  final String status;
  final String notes;
  final String? customerName;
  final double? runningBalance;
  final String? reference;
  final String? description;

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
