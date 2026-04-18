import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async => await _auth.canCheckBiometrics;

  Future<bool> authenticate() async {
    final available = await isBiometricAvailable();
    if (!available) return false;
    return await _auth.authenticate(localizedReason: 'Please authenticate to continue');
  }
}
