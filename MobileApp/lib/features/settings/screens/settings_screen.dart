import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/auth/biometric_auth.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/core/network/connectivity_service.dart';
import 'package:qadaya_lawyersys/core/notifications/push_notification_service.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/core/storage/preferences_storage.dart';
import 'package:qadaya_lawyersys/core/theme/theme_cubit.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_bloc.dart';
import 'package:qadaya_lawyersys/features/authentication/bloc/auth_event.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key, this.biometricAuthService});
  final BiometricAuthService? biometricAuthService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en';
  bool _pushNotificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  final _preferences = PreferencesStorage();
  final _pushService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final storedLanguage = await _preferences.getLanguageCode();
    final storedPush = await _preferences.getPushNotificationEnabled();
    final biometricService = widget.biometricAuthService ?? BiometricAuthService();
    final biometricAvailable = await biometricService.isBiometricAvailable();
    final session = await authRepository.getStoredSession();

    try {
      await LocalDatabase.instance.getSyncQueueSize();
      await ConnectivityService().getPersistedHealth();
    } catch (e) {
      debugPrint('SettingsScreen: unable to init local persistence for settings: $e');
    }

    if (!mounted) return;
    setState(() {
      _language = storedLanguage ?? 'en';
      _pushNotificationsEnabled = storedPush;
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = session?.biometricEnabled ?? false;
    });
  }

  Future<void> _setPushNotificationsEnabled(bool enabled) async {
    await _preferences.setPushNotificationEnabled(enabled);
    setState(() {
      _pushNotificationsEnabled = enabled;
    });

    if (enabled) {
      await _pushService.init();
    } else {
      await _pushService.disable();
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    await _preferences.setLanguageCode(languageCode);
    if (!mounted) return;
    setState(() {
      _language = languageCode;
    });
    unawaited(Navigator.pushReplacementNamed(context, '/'));
  }

  Future<void> _setBiometricEnabled(bool enabled) async {
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final success = await authRepository.setBiometricEnabled(enabled);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unableToUpdateBiometricSettings)));
      return;
    }
    setState(() {
      _biometricEnabled = enabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? l.biometricEnabled : l.biometricDisabled)));
  }

  String _getThemeModeLabel(ThemeMode mode, AppLocalizations localizer) {
    switch (mode) {
      case ThemeMode.light:
        return localizer.lightMode;
      case ThemeMode.dark:
        return localizer.darkMode;
      case ThemeMode.system:
        return localizer.systemDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizer.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(localizer.language),
            subtitle: Text(_language == 'ar' ? localizer.arabic : localizer.english),
          ),
          RadioGroup<String>(
            groupValue: _language,
            onChanged: (value) { if (value != null) _setLanguage(value); },
            child: Column(
              children: [
                ListTile(
                  title: Text(localizer.english),
                  leading: const Radio<String>(value: 'en'),
                  onTap: () => _setLanguage('en'),
                ),
                ListTile(
                  title: Text(localizer.arabic),
                  leading: const Radio<String>(value: 'ar'),
                  onTap: () => _setLanguage('ar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(localizer.theme),
                    subtitle: Text(_getThemeModeLabel(themeMode, localizer)),
                    leading: const Icon(Icons.brightness_6),
                  ),
                  RadioGroup<ThemeMode>(
                    groupValue: themeMode,
                    onChanged: (value) {
                      if (value == ThemeMode.light) {
                        context.read<ThemeCubit>().setLightMode();
                      } else if (value == ThemeMode.dark) {
                        context.read<ThemeCubit>().setDarkMode();
                      } else if (value == ThemeMode.system) {
                        context.read<ThemeCubit>().setSystemMode();
                      }
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(localizer.lightMode),
                          leading: const Radio<ThemeMode>(value: ThemeMode.light),
                          onTap: () => context.read<ThemeCubit>().setLightMode(),
                        ),
                        ListTile(
                          title: Text(localizer.darkMode),
                          leading: const Radio<ThemeMode>(value: ThemeMode.dark),
                          onTap: () => context.read<ThemeCubit>().setDarkMode(),
                        ),
                        ListTile(
                          title: Text(localizer.systemDefault),
                          leading: const Radio<ThemeMode>(value: ThemeMode.system),
                          onTap: () => context.read<ThemeCubit>().setSystemMode(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(localizer.pushNotifications),
            value: _pushNotificationsEnabled,
            onChanged: _setPushNotificationsEnabled,
            secondary: const Icon(Icons.notifications_active),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              title: Text(localizer.biometricLogin),
              subtitle: Text(_biometricEnabled ? localizer.biometricEnabled : localizer.biometricDisabled),
              value: _biometricEnabled,
              onChanged: _setBiometricEnabled,
              secondary: const Icon(Icons.fingerprint),
            ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(localizer.logout),
            onTap: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 16),
          Text('App version 0.1.0', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

