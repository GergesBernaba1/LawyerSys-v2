import '../authentication/models/user_session.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserSession session;
  AuthAuthenticated(this.session);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
class AuthRegisterLoading extends AuthState {}
class AuthRegisterSuccess extends AuthState {}
class AuthForgotPasswordLoading extends AuthState {}
class AuthForgotPasswordSuccess extends AuthState {}
class AuthResetPasswordLoading extends AuthState {}
class AuthResetPasswordSuccess extends AuthState {}
