class UserModel {
  final String id;
  final String fullName;
  final String userName;
  final String? email;
  final String? phoneNumber;
  final String? job;
  final bool isActive;

  UserModel({
    required this.id,
    required this.fullName,
    required this.userName,
    this.email,
    this.phoneNumber,
    this.job,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? json['Id'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
        userName: (json['userName'] ?? json['UserName'] ?? '').toString(),
        email: (json['email'] ?? json['Email'])?.toString(),
        phoneNumber: (json['phoneNumber'] ?? json['PhoneNumber'])?.toString(),
        job: (json['job'] ?? json['Job'])?.toString(),
        isActive: json['isActive'] ?? json['IsActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'userName': userName,
        'email': email,
        'phoneNumber': phoneNumber,
        'job': job,
        'isActive': isActive,
      };
}
