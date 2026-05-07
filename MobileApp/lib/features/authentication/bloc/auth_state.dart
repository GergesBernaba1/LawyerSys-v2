import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.session);
  final UserSession session;
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}
class AuthRegisterLoading extends AuthState {}
class AuthRegisterSuccess extends AuthState {}
class AuthForgotPasswordLoading extends AuthState {}
class AuthForgotPasswordSuccess extends AuthState {}
class AuthResetPasswordLoading extends AuthState {}
class AuthResetPasswordSuccess extends AuthState {}
