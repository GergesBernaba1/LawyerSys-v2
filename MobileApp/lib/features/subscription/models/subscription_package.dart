class SubscriptionPackage {
  final String officeSize;
  final String? name;
  final double? monthlyPrice;
  final double? yearlyPrice;
  final int? maxUsers;
  final int? maxCases;
  final int? maxStorage; // in MB
  final List<String> features;
  final bool isPopular;

  SubscriptionPackage({
    required this.officeSize,
    this.name,
    this.monthlyPrice,
    this.yearlyPrice,
    this.maxUsers,
    this.maxCases,
    this.maxStorage,
    required this.features,
    required this.isPopular,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final List<String> featureList;
    if (rawFeatures is List) {
      featureList = rawFeatures.map((f) => f.toString()).toList();
    } else {
      featureList = const [];
    }

    return SubscriptionPackage(
      officeSize: json['officeSize'] as String? ?? '',
      name: json['name'] as String?,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble(),
      maxUsers: json['maxUsers'] as int?,
      maxCases: json['maxCases'] as int?,
      maxStorage: json['maxStorage'] as int?,
      features: featureList,
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'officeSize': officeSize,
      'name': name,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'maxUsers': maxUsers,
      'maxCases': maxCases,
      'maxStorage': maxStorage,
      'features': features,
      'isPopular': isPopular,
    };
  }
}
