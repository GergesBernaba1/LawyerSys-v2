class ContenderModel {
  ContenderModel({
    required this.contenderId,
    required this.fullName,
    required this.ssn,
    this.birthDate,
    this.type,
  });

  factory ContenderModel.fromJson(Map<String, dynamic> json) => ContenderModel(
        contenderId: json['id']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        ssn: json['ssn']?.toString() ?? '',
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate'].toString())
            : null,
        type: json['type'] as bool?,
      );

  final String contenderId;
  final String fullName;
  final String ssn;
  final DateTime? birthDate;

  /// true = Plaintiff, false = Defendant, null = unspecified
  final bool? type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'ssn': ssn,
      if (type != null) 'type': type,
    };
    if (birthDate != null) {
      final y = birthDate!.year.toString().padLeft(4, '0');
      final m = birthDate!.month.toString().padLeft(2, '0');
      final d = birthDate!.day.toString().padLeft(2, '0');
      map['birthDate'] = '$y-$m-$d';
    }
    return map;
  }
}
