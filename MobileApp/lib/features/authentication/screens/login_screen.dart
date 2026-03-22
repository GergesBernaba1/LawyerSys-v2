import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../../core/localization/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

// ─── Theme constants matching ClientApp ───────────────────────────────────────
const _kPrimary = Color(0xFF14345A);
const _kPrimaryLight = Color(0xFF2D6A87);
const _kGold = Color(0xFFB98746);
const _kBg = Color(0xFFEEF4FA);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    BiometricAuthService().isBiometricAvailable().then((available) {
      if (mounted) setState(() => _isBiometricAvailable = available);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimary));
          }
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / brand
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimary, _kPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.gavel,
                            color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizer.login,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _kPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizer.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF5F7085), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 36),

                    // Email field
                    _buildField(
                      controller: _emailController,
                      label: localizer.email,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _buildField(
                      controller: _passwordController,
                      label: localizer.password,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF5F7085),
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/forgot-password'),
                        child: Text(
                          localizer.forgotPassword,
                          style: const TextStyle(
                              color: _kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    _buildPrimaryButton(
                      label: localizer.login,
                      onPressed: () {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${localizer.email} and ${localizer.password} are required')));
                          return;
                        }
                        context
                            .read<AuthBloc>()
                            .add(LoginRequested(email, password));
                      },
                    ),

                    if (_isBiometricAvailable) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(BiometricLoginRequested()),
                        icon: const Icon(Icons.fingerprint, color: _kPrimary),
                        label: Text(
                          localizer.biometricLogin,
                          style: const TextStyle(
                              color: _kPrimary, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _kPrimary, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizer.noAccount,
                            style: const TextStyle(color: Color(0xFF5F7085))),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: Text(
                            localizer.register,
                            style: const TextStyle(
                                color: _kGold, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1F14345A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1F14345A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
      {required String label, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, _kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }
}
