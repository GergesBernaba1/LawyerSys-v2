class LoginRequest {

  LoginRequest({required this.userName, required this.password});
  final String userName;
  final String password;

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'password': password,
  };
}


