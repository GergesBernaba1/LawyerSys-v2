class CustomerPaymentProof {

  CustomerPaymentProof({
    required this.id,
    required this.customerId,
    this.caseCode,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
    required this.notes,
    this.proofFileId,
    required this.proofFileCode,
    required this.proofFilePath,
    required this.status,
    this.billingPaymentId,
    required this.reviewNotes,
    required this.submittedAtUtc,
    this.reviewedAtUtc,
  });

  factory CustomerPaymentProof.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentProof(
      id: (json['id'] as int?) ?? 0,
      customerId: (json['customerId'] as int?) ?? 0,
      caseCode: json['caseCode'] as int?,
      customerName: json['customerName']?.toString() ?? '',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : DateTime.now(),
      notes: json['notes']?.toString() ?? '',
      proofFileId: json['proofFileId'] as int?,
      proofFileCode: json['proofFileCode']?.toString() ?? '',
      proofFilePath: json['proofFilePath']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      billingPaymentId: json['billingPaymentId'] as int?,
      reviewNotes: json['reviewNotes']?.toString() ?? '',
      submittedAtUtc: json['submittedAtUtc'] != null
          ? DateTime.parse(json['submittedAtUtc'] as String)
          : DateTime.now(),
      reviewedAtUtc: json['reviewedAtUtc'] != null
          ? DateTime.parse(json['reviewedAtUtc'] as String)
          : null,
    );
  }
  final int id;
  final int customerId;
  final int? caseCode;
  final String customerName;
  final double amount;
  final DateTime paymentDate;
  final String notes;
  final int? proofFileId;
  final String proofFileCode;
  final String proofFilePath;
  final String status;
  final int? billingPaymentId;
  final String reviewNotes;
  final DateTime submittedAtUtc;
  final DateTime? reviewedAtUtc;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}
