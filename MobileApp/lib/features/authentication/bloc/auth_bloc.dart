import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/biometric_auth.dart';
import '../authentication/models/login_request.dart';
import '../authentication/models/user_session.dart';
import '../authentication/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final BiometricAuthService biometricService;

  AuthBloc({required this.authRepository, BiometricAuthService? biometricService})
      : biometricService = biometricService ?? BiometricAuthService(),
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionRestored>(_onSessionRestored);
    on<BiometricLoginRequested>(_onBiometricLoginRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final session = await authRepository.login(LoginRequest(email: event.email, password: event.password));

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await authRepository.registerDeviceToken(fcmToken);
      }

      emit(AuthAuthenticated(session));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onBiometricLoginRequested(BiometricLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final session = await authRepository.getStoredSession();
      if (session == null || !session.biometricEnabled) {
        emit(AuthUnauthenticated());
        return;
      }

      final available = await biometricService.isBiometricAvailable();
      if (!available) {
        emit(AuthUnauthenticated());
        return;
      }

      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        emit(AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(session));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthRegisterLoading());
    try {
      // TODO: Implement register API call
      // For now, we'll simulate success
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthRegisterSuccess());
      // Navigate to login screen after successful registration
      // This would typically be handled in the UI layer
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthForgotPasswordLoading());
    try {
      // TODO: Implement forgot password API call
      // For now, we'll simulate success
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthForgotPasswordSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthResetPasswordLoading());
    try {
      // TODO: Implement reset password API call
      // For now, we'll simulate success
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await authRepository.logout();
    } catch (_) {
      // ignore, still clear local session state
    }
    emit(AuthUnauthenticated());
  }

  Future<void> _onSessionRestored(SessionRestored event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final stored = await authRepository.getStoredSession();
      if (stored == null) {
        emit(AuthUnauthenticated());
        return;
      }

      if (stored.biometricEnabled) {
        final available = await biometricService.isBiometricAvailable();
        if (available) {
          final authenticated = await biometricService.authenticate();
          if (authenticated) {
            emit(AuthAuthenticated(stored));
            return;
          }
          emit(AuthUnauthenticated());
          return;
        }
      }

      emit(AuthAuthenticated(stored));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
}

