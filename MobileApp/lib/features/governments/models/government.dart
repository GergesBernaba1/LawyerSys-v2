class Government {
  Government({required this.governorateId, required this.governorateName});

  factory Government.fromJson(Map<String, dynamic> json) => Government(
        governorateId: json['id']?.toString() ?? '',
        governorateName: json['govName']?.toString() ?? '',
      );
  final String governorateId;
  final String governorateName;

  Map<String, dynamic> toJson() => {
        'id': governorateId,
        'govName': governorateName,
      };
}
