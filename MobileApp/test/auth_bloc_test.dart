import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/auth/biometric_auth.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_event.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';
import 'package:qadaya_lawyersys/features/authentication/models/login_request.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';

class FakeAuthRepository extends AuthRepository {

  FakeAuthRepository() : super(ApiClient());
  UserSession? currentSession;

  @override
  Future<UserSession?> getStoredSession() async => currentSession;

  @override
  Future<UserSession> login(LoginRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<UserSession?> refreshToken(String refreshToken) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    currentSession = null;
  }

  @override
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (currentSession == null) return false;
    currentSession = UserSession(
      userId: currentSession!.userId,
      email: currentSession!.email,
      fullName: currentSession!.fullName,
      tenantId: currentSession!.tenantId,
      tenantName: currentSession!.tenantName,
      accessToken: currentSession!.accessToken,
      refreshToken: currentSession!.refreshToken,
      tokenExpiresAt: currentSession!.tokenExpiresAt,
      roles: currentSession!.roles,
      permissions: currentSession!.permissions,
      languageCode: currentSession!.languageCode,
      biometricEnabled: enabled,
    );
    return true;
  }
}

class FakeBiometricAuthService extends BiometricAuthService {

  FakeBiometricAuthService({this.available = true, this.authenticated = true});
  final bool available;
  final bool authenticated;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> authenticate() async => authenticated;
}

void main() {
  final now = DateTime.now().add(const Duration(hours: 1));

  group('AuthBloc biometric and session flow', () {
    test('BiometricLoginRequested success emits AuthAuthenticated', () async {
      final repository = FakeAuthRepository();
      repository.currentSession = UserSession(
        userId: 'u1',
        email: 'test@example.com',
        fullName: 'Test User',
        tenantId: 't1',
        tenantName: 'Tenant One',
        accessToken: 'tk',
        refreshToken: 'rt',
        tokenExpiresAt: now,
        roles: [],
        permissions: [],
        languageCode: 'en',
        biometricEnabled: true,
      );
      final bloc = AuthBloc(authRepository: repository, biometricService: FakeBiometricAuthService());

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(BiometricLoginRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());
      expect((states[1] as AuthAuthenticated).session.email, 'test@example.com');
      await bloc.close();
    });

    test('BiometricLoginRequested unavailable emits AuthUnauthenticated', () async {
      final repository = FakeAuthRepository();
      repository.currentSession = UserSession(
        userId: 'u1',
        email: 'test@example.com',
        fullName: 'Test User',
        tenantId: 't1',
        tenantName: 'Tenant One',
        accessToken: 'tk',
        refreshToken: 'rt',
        tokenExpiresAt: now,
        roles: [],
        permissions: [],
        languageCode: 'en',
        biometricEnabled: true,
      );
      final bloc = AuthBloc(authRepository: repository, biometricService: FakeBiometricAuthService(available: false, authenticated: false));

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(BiometricLoginRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthUnauthenticated>());
      await bloc.close();
    });

    test('SessionRestored with biometric on and authenticate success emits AuthAuthenticated', () async {
      final repository = FakeAuthRepository();
      repository.currentSession = UserSession(
        userId: 'u1',
        email: 'test@example.com',
        fullName: 'Test User',
        tenantId: 't1',
        tenantName: 'Tenant One',
        accessToken: 'tk',
        refreshToken: 'rt',
        tokenExpiresAt: now,
        roles: [],
        permissions: [],
        languageCode: 'en',
        biometricEnabled: true,
      );
      final bloc = AuthBloc(authRepository: repository, biometricService: FakeBiometricAuthService());

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(SessionRestored());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());
      await bloc.close();
    });

    test('SessionRestored with biometric off emits AuthAuthenticated directly', () async {
      final repository = FakeAuthRepository();
      repository.currentSession = UserSession(
        userId: 'u1',
        email: 'test@example.com',
        fullName: 'Test User',
        tenantId: 't1',
        tenantName: 'Tenant One',
        accessToken: 'tk',
        refreshToken: 'rt',
        tokenExpiresAt: now,
        roles: [],
        permissions: [],
        languageCode: 'en',
        biometricEnabled: false,
      );
      final bloc = AuthBloc(authRepository: repository, biometricService: FakeBiometricAuthService(authenticated: false));

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(SessionRestored());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthAuthenticated>());
      await bloc.close();
    });
  });
}
