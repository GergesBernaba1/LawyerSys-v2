import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/auth/biometric_auth.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/storage/secure_storage.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_event.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_state.dart';

// Theme constants matching ClientApp
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
  final _secureStorage = SecureStorage();
  bool _isBiometricAvailable = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    BiometricAuthService().isBiometricAvailable().then((available) {
      if (mounted) setState(() => _isBiometricAvailable = available);
    });
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await _secureStorage.read(SecureStorage.keyRememberMe);
    if (rememberMe != 'true') return;
    final email = await _secureStorage.read(SecureStorage.keySavedEmail);
    final password = await _secureStorage.read(SecureStorage.keySavedPassword);
    if (!mounted) return;
    setState(() {
      _rememberMe = true;
      if (email != null) _emailController.text = email;
      if (password != null) _passwordController.text = password;
    });
  }

  Future<void> _saveOrClearCredentials(String email, String password) async {
    if (_rememberMe) {
      await _secureStorage.write(SecureStorage.keyRememberMe, 'true');
      await _secureStorage.write(SecureStorage.keySavedEmail, email);
      await _secureStorage.write(SecureStorage.keySavedPassword, password);
    } else {
      await _secureStorage.write(SecureStorage.keyRememberMe, 'false');
      await _secureStorage.delete(SecureStorage.keySavedEmail);
      await _secureStorage.delete(SecureStorage.keySavedPassword);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

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
                child: CircularProgressIndicator(color: _kPrimary),);
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
                      child: Semantics(
                        label: 'LawyerSys application logo',
                        excludeSemantics: true,
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
                              color: Colors.white, size: 36,),
                        ),
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
                          color: Color(0xFF5F7085), fontWeight: FontWeight.w600,),
                    ),
                    const SizedBox(height: 36),

                    // Email field
                    Semantics(
                      label: 'Email address input field',
                      hint: 'Enter your email address',
                      textField: true,
                      child: _buildField(
                        controller: _emailController,
                        label: localizer.email,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Semantics(
                      label: 'Password input field',
                      hint: 'Enter your password',
                      textField: true,
                      obscured: _obscurePassword,
                      child: _buildField(
                        controller: _passwordController,
                        label: localizer.password,
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: Semantics(
                          label: _obscurePassword ? 'Show password' : 'Hide password',
                          button: true,
                          onTapHint: 'Toggle password visibility',
                          child: IconButton(
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
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Remember me + Forgot password row
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: _kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) =>
                                setState(() => _rememberMe = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            localizer.rememberMe,
                            style: const TextStyle(
                              color: Color(0xFF5F7085),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/forgot-password',),
                          child: Text(
                            localizer.forgotPassword,
                            style: const TextStyle(
                                color: _kPrimary, fontWeight: FontWeight.w700,),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Login button
                    Semantics(
                      label: 'Login button',
                      hint: 'Tap to log in with email and password',
                      button: true,
                      child: _buildPrimaryButton(
                        label: localizer.login,
                        onPressed: () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    '${localizer.email} and ${localizer.password} are required',),),);
                            return;
                          }
                          unawaited(_saveOrClearCredentials(email, password));
                          context
                              .read<AuthBloc>()
                              .add(LoginRequested(email, password));
                        },
                      ),
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
                              color: _kPrimary, fontWeight: FontWeight.w700,),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _kPrimary, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizer.noAccount,
                            style: const TextStyle(color: Color(0xFF5F7085)),),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: Text(
                            localizer.register,
                            style: const TextStyle(
                                color: _kGold, fontWeight: FontWeight.w800,),
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
      {required String label, required VoidCallback onPressed,}) {
    return DecoratedBox(
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
              borderRadius: BorderRadius.circular(14),),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,),),
      ),
    );
  }
}
