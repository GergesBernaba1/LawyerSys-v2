class Government {
  final String governorateId;
  final String governorateName;

  Government({required this.governorateId, required this.governorateName});

  factory Government.fromJson(Map<String, dynamic> json) => Government(
        governorateId: json['governorateId']?.toString() ?? '',
        governorateName: json['governorateName']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'governorateId': governorateId,
        'governorateName': governorateName,
      };
}
