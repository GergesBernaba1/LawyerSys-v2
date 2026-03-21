import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../core/localization/app_localizations.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    BiometricAuthService().isBiometricAvailable().then((available) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = available;
        });
      }
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
      appBar: AppBar(title: Text(localizer.login)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.pushReplacementNamed(context, '/main');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: localizer.email),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: localizer.password),
                ),
                const SizedBox(height: 24),
                if (_isBiometricAvailable)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(BiometricLoginRequested());
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: Text(localizer.biometricLogin),
                    ),
                  ),
                if (_isBiometricAvailable) const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizer.error + ': ' + localizer.email + ' and ' + localizer.password + ' are required')));
                        return;
                      }
                      context.read<AuthBloc>().add(LoginRequested(email, password));
                    },
                    child: Text(localizer.login),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

