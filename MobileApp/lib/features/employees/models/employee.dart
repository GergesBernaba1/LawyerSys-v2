class EmployeeModel {

  EmployeeModel({
    required this.id,
    required this.salary,
    required this.usersId,
    this.user,
    this.identity,
    this.profileImagePath,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: _asInt(json['id'] ?? json['Id']),
        salary: _asInt(json['salary'] ?? json['Salary']),
        usersId: _asInt(json['usersId'] ?? json['UsersId']),
        user: json['user'] != null
            ? UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map))
            : (json['User'] != null
                ? UserModel.fromJson(
                    Map<String, dynamic>.from(json['User'] as Map),)
                : null),
        identity: json['identity'] != null
            ? IdentityUserInfoModel.fromJson(
                Map<String, dynamic>.from(json['identity'] as Map),)
            : (json['Identity'] != null
                ? IdentityUserInfoModel.fromJson(
                    Map<String, dynamic>.from(json['Identity'] as Map),)
                : null),
        profileImagePath: (json['profileImagePath'] ??
                json['ProfileImagePath'] ??
                (json['user'] as Map<String, dynamic>?)?['profileImagePath'] ??
                (json['User'] as Map<String, dynamic>?)?['ProfileImagePath'])
            ?.toString(),
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.tryParse(json['lastSyncedAt'] as String)
            : null,
        isDirty: (json['isDirty'] as bool?) ?? false,
      );
  final int id;
  final int salary;
  final int usersId;
  final UserModel? user;
  final IdentityUserInfoModel? identity;
  final String? profileImagePath;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'salary': salary,
        'usersId': usersId,
        'user': user?.toJson(),
        'identity': identity?.toJson(),
        'profileImagePath': profileImagePath,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isDirty': isDirty,
      };
}

class UserModel {

  UserModel({
    required this.id,
    required this.fullName,
    this.address,
    required this.job,
    required this.phoneNumber,
    this.dateOfBirth,
    required this.ssn,
    required this.userName,
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: EmployeeModel._asInt(json['id'] ?? json['Id']),
        fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
        address: (json['address'] ?? json['Address'])?.toString(),
        job: (json['job'] ?? json['Job'] ?? '').toString(),
        phoneNumber:
            (json['phoneNumber'] ?? json['PhoneNumber'] ?? '').toString(),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateOnly.tryParse(json['dateOfBirth'].toString())
            : (json['DateOfBirth'] != null
                ? DateOnly.tryParse(json['DateOfBirth'].toString())
                : null),
        ssn: (json['ssn'] ?? json['SSN'] ?? '').toString(),
        userName: (json['userName'] ?? json['UserName'] ?? '').toString(),
        profileImagePath:
            (json['profileImagePath'] ?? json['ProfileImagePath'])?.toString(),
      );
  final int id;
  final String fullName;
  final String? address;
  final String job;
  final String phoneNumber;
  final DateOnly? dateOfBirth;
  final String ssn;
  final String userName;
  final String? profileImagePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'address': address,
        'job': job,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth?.toString(),
        'ssn': ssn,
        'userName': userName,
        'profileImagePath': profileImagePath,
      };
}

class IdentityUserInfoModel {

  IdentityUserInfoModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    required this.emailConfirmed,
    required this.requiresPasswordReset,
  });

  factory IdentityUserInfoModel.fromJson(Map<String, dynamic> json) =>
      IdentityUserInfoModel(
        id: (json['id'] as String?) ?? '',
        userName: (json['userName'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        fullName: (json['fullName'] as String?) ?? '',
        emailConfirmed: (json['emailConfirmed'] as bool?) ?? false,
        requiresPasswordReset: (json['requiresPasswordReset'] as bool?) ?? false,
      );
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final bool emailConfirmed;
  final bool requiresPasswordReset;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'email': email,
        'fullName': fullName,
        'emailConfirmed': emailConfirmed,
        'requiresPasswordReset': requiresPasswordReset,
      };
}

class DateOnly {

  DateOnly({required this.year, required this.month, required this.day});

  factory DateOnly.tryParse(String? value) {
    if (value == null || value.isEmpty) {
      return DateOnly(year: 0, month: 0, day: 0);
    }
    try {
      final parts = value.split('-');
      return DateOnly(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        day: int.parse(parts[2]),
      );
    } catch (_) {
      return DateOnly(year: 0, month: 0, day: 0);
    }
  }
  final int year;
  final int month;
  final int day;

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
