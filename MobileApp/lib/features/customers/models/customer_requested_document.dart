class CustomerRequestedDocument {

  CustomerRequestedDocument({
    required this.id,
    required this.caseCode,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.description,
    this.dueDate,
    required this.status,
    required this.requestedByName,
    required this.customerNotes,
    required this.reviewNotes,
    this.uploadedFileId,
    required this.uploadedFileCode,
    required this.uploadedFilePath,
    required this.requestedAtUtc,
    this.submittedAtUtc,
    this.reviewedAtUtc,
  });

  factory CustomerRequestedDocument.fromJson(Map<String, dynamic> json) {
    return CustomerRequestedDocument(
      id: (json['id'] as int?) ?? 0,
      caseCode: (json['caseCode'] as int?) ?? 0,
      customerId: (json['customerId'] as int?) ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      status: json['status']?.toString() ?? 'Pending',
      requestedByName: json['requestedByName']?.toString() ?? '',
      customerNotes: json['customerNotes']?.toString() ?? '',
      reviewNotes: json['reviewNotes']?.toString() ?? '',
      uploadedFileId: json['uploadedFileId'] as int?,
      uploadedFileCode: json['uploadedFileCode']?.toString() ?? '',
      uploadedFilePath: json['uploadedFilePath']?.toString() ?? '',
      requestedAtUtc: json['requestedAtUtc'] != null
          ? DateTime.parse(json['requestedAtUtc'] as String)
          : DateTime.now(),
      submittedAtUtc: json['submittedAtUtc'] != null
          ? DateTime.parse(json['submittedAtUtc'] as String)
          : null,
      reviewedAtUtc: json['reviewedAtUtc'] != null
          ? DateTime.parse(json['reviewedAtUtc'] as String)
          : null,
    );
  }
  final int id;
  final int caseCode;
  final int customerId;
  final String customerName;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String status;
  final String requestedByName;
  final String customerNotes;
  final String reviewNotes;
  final int? uploadedFileId;
  final String uploadedFileCode;
  final String uploadedFilePath;
  final DateTime requestedAtUtc;
  final DateTime? submittedAtUtc;
  final DateTime? reviewedAtUtc;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSubmitted => status.toLowerCase() == 'submitted';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}
