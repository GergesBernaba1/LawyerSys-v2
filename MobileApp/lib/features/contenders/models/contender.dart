class ContenderModel {

  ContenderModel({
    required this.contenderId,
    required this.fullName,
    required this.ssn,
    this.birthDate,
    required this.phone,
    required this.email,
    required this.address,
    required this.contenderType,
    required this.notes,
  });

  factory ContenderModel.fromJson(Map<String, dynamic> json) => ContenderModel(
        contenderId: json['contenderId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        ssn: json['ssn']?.toString() ?? '',
        birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null,
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        contenderType: json['contenderType']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
  final String contenderId;
  final String fullName;
  final String ssn;
  final DateTime? birthDate;
  final String phone;
  final String email;
  final String address;
  final String contenderType;
  final String notes;

  Map<String, dynamic> toJson() => {
        'contenderId': contenderId,
        'fullName': fullName,
        'ssn': ssn,
        'birthDate': birthDate?.toIso8601String(),
        'phone': phone,
        'email': email,
        'address': address,
        'contenderType': contenderType,
        'notes': notes,
      };
}
