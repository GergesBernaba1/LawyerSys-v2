class CourtModel {
  final String courtId;
  final String name;
  final String address;
  final String governorate;
  final String phone;
  final String notes;

  CourtModel({
    required this.courtId,
    required this.name,
    required this.address,
    required this.governorate,
    required this.phone,
    required this.notes,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) => CourtModel(
        courtId: json['courtId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        governorate: json['governorate']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'courtId': courtId,
        'name': name,
        'address': address,
        'governorate': governorate,
        'phone': phone,
        'notes': notes,
      };
}
