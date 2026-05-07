class Customer {

  Customer({
    required this.customerId,
    required this.fullName,
    this.phoneNumber,
    this.ssn,
    this.email,
    this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        customerId: json['customerId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString(),
        ssn: json['ssn']?.toString(),
        email: json['email']?.toString(),
        address: json['address']?.toString(),
      );
  final String customerId;
  final String fullName;
  final String? phoneNumber;
  final String? ssn;
  final String? email;
  final String? address;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'ssn': ssn,
        'email': email,
        'address': address,
      };
}

class CustomerCaseHistoryItem {

  CustomerCaseHistoryItem({
    required this.caseId,
    required this.caseName,
    required this.caseCode,
    required this.assignedEmployeeName,
  });

  factory CustomerCaseHistoryItem.fromJson(Map<String, dynamic> json) {
    final assignedEmployee = json['assignedEmployee'] as Map<String, dynamic>?;
    return CustomerCaseHistoryItem(
      caseId: json['caseId']?.toString() ?? json['caseId']?.toString() ?? '',
      caseName: json['caseName']?.toString() ?? '',
      caseCode: json['code']?.toString() ?? '',
      assignedEmployeeName: assignedEmployee != null
          ? assignedEmployee['fullName']?.toString() ?? ''
          : '',
    );
  }
  final String caseId;
  final String caseName;
  final String caseCode;
  final String assignedEmployeeName;
}
