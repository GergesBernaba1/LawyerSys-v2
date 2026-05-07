class JudicialDocument {

  JudicialDocument({
    required this.id,
    required this.docType,
    required this.docNum,
    required this.docDetails,
    required this.notes,
    required this.numOfAgent,
    required this.customerId,
    this.customerName,
  });

  factory JudicialDocument.fromJson(Map<String, dynamic> json) => JudicialDocument(
        id: json['id'] as int? ?? 0,
        docType: json['docType']?.toString() ?? '',
        docNum: json['docNum'] as int? ?? 0,
        docDetails: json['docDetails']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        numOfAgent: json['numOfAgent'] as int? ?? 0,
        customerId: json['customerId'] as int? ?? 0,
        customerName: json['customerName']?.toString(),
      );
  final int id;
  final String docType;
  final int docNum;
  final String docDetails;
  final String notes;
  final int numOfAgent;
  final int customerId;
  final String? customerName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'docType': docType,
        'docNum': docNum,
        'docDetails': docDetails,
        'notes': notes,
        'numOfAgent': numOfAgent,
        'customerId': customerId,
        'customerName': customerName,
      };
}
