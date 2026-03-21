abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}
class RegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  RegisterRequested(this.firstName, this.lastName, this.email, this.phone, this.password);
}
class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested(this.email);
}
class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String password;
  final String token;
  ResetPasswordRequested(this.email, this.password, this.token);
}
class LogoutRequested extends AuthEvent {}
class SessionRestored extends AuthEvent {}
class BiometricLoginRequested extends AuthEvent {}
class TokenRefreshRequested extends AuthEvent {}
