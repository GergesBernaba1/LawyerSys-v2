class TenantModel {
  final int id;
  final String name;
  final String countryName;
  final bool isActive;
  final int userCount;
  final String packageName;
  final bool isCurrent;

  TenantModel({
    required this.id,
    required this.name,
    required this.countryName,
    required this.isActive,
    required this.userCount,
    required this.packageName,
    required this.isCurrent,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json, {int? currentTenantId}) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse((json['id'] ?? '').toString()) ?? 0;
    return TenantModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      countryName: (json['countryName'] ?? '').toString(),
      isActive: json['isActive'] == true,
      userCount: json['userCount'] is int
          ? json['userCount'] as int
          : int.tryParse((json['userCount'] ?? '0').toString()) ?? 0,
      packageName: (json['currentPackageName'] ?? '').toString(),
      isCurrent: currentTenantId != null && id == currentTenantId,
    );
  }
}

class TenantSelectionModel {
  final int? currentTenantId;
  final bool isSuperAdmin;
  final List<TenantModel> tenants;

  TenantSelectionModel({
    required this.currentTenantId,
    required this.isSuperAdmin,
    required this.tenants,
  });
}
