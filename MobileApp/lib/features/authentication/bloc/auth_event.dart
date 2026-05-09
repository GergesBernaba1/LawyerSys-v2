abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  LoginRequested(this.email, this.password, {this.rememberMe = false});
  final String email;
  final String password;
  final bool rememberMe;
}
class RegisterRequested extends AuthEvent {
  RegisterRequested(this.firstName, this.lastName, this.email, this.phone, this.password);
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
}
class ForgotPasswordRequested extends AuthEvent {
  ForgotPasswordRequested(this.email);
  final String email;
}
class ResetPasswordRequested extends AuthEvent {
  ResetPasswordRequested(this.email, this.password, this.token);
  final String email;
  final String password;
  final String token;
}
class LogoutRequested extends AuthEvent {}
class SessionRestored extends AuthEvent {}
class BiometricLoginRequested extends AuthEvent {}
class TokenRefreshRequested extends AuthEvent {}
