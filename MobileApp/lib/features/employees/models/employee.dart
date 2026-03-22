class EmployeeModel {
  final int id;
  final int salary;
  final int usersId;
  final UserModel? user;
  final IdentityUserInfoModel? identity;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  EmployeeModel({
    required this.id,
    required this.salary,
    required this.usersId,
    this.user,
    this.identity,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
    id: json['id'] ?? 0,
    salary: json['salary'] ?? 0,
    usersId: json['usersId'] ?? 0,
    user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    identity: json['identity'] != null ? IdentityUserInfoModel.fromJson(json['identity']) : null,
    lastSyncedAt: json['lastSyncedAt'] != null ? DateTime.tryParse(json['lastSyncedAt']) : null,
    isDirty: json['isDirty'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'salary': salary,
    'usersId': usersId,
    'user': user?.toJson(),
    'identity': identity?.toJson(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'isDirty': isDirty,
  };
}

class UserModel {
  final int id;
  final String fullName;
  final String? address;
  final String job;
  final String phoneNumber;
  final DateOnly? dateOfBirth;
  final String ssn;
  final String userName;

  UserModel({
    required this.id,
    required this.fullName,
    this.address,
    required this.job,
    required this.phoneNumber,
    this.dateOfBirth,
    required this.ssn,
    required this.userName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? 0,
    fullName: json['fullName'] ?? '',
    address: json['address'],
    job: json['job'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    dateOfBirth: json['dateOfBirth'] != null ? DateOnly.tryParse(json['dateOfBirth']) : null,
    ssn: json['ssn'] ?? '',
    userName: json['userName'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'address': address,
    'job': job,
    'phoneNumber': phoneNumber,
    'dateOfBirth': dateOfBirth?.toString(),
    'ssn': ssn,
    'userName': userName,
  };
}

class IdentityUserInfoModel {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final bool emailConfirmed;
  final bool requiresPasswordReset;

  IdentityUserInfoModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    required this.emailConfirmed,
    required this.requiresPasswordReset,
  });

  factory IdentityUserInfoModel.fromJson(Map<String, dynamic> json) => IdentityUserInfoModel(
    id: json['id'] ?? '',
    userName: json['userName'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    emailConfirmed: json['emailConfirmed'] ?? false,
    requiresPasswordReset: json['requiresPasswordReset'] ?? false,
  );

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
  final int year;
  final int month;
  final int day;

  DateOnly({required this.year, required this.month, required this.day});

  factory DateOnly.tryParse(String? value) {
    if (value == null || value.isEmpty) return DateOnly(year: 0, month: 0, day: 0);
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

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
