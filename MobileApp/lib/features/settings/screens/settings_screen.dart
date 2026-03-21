import 'package:flutter/material.dart';

import '../../../core/auth/biometric_auth.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../authentication/bloc/auth_bloc.dart';
import '../../authentication/bloc/auth_event.dart';
import '../../authentication/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'en';
  bool _pushNotificationsEnabled = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  int _queueSize = 0;
  String _lastSync = 'Unknown';
  String _syncStatus = 'No data';
  bool _isForceSyncing = false;
  final _preferences = PreferencesStorage();
  final _pushService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storedLanguage = await _preferences.getLanguageCode();
    final storedPush = await _preferences.getPushNotificationEnabled();
    final biometricAvailable = await BiometricAuthService().isBiometricAvailable();
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final session = await authRepository.getStoredSession();

    final queueSize = await LocalDatabase.instance.getSyncQueueSize();
    final persisted = await ConnectivityService().getPersistedHealth();

    setState(() {
      _language = storedLanguage ?? 'en';
      _pushNotificationsEnabled = storedPush;
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = session?.biometricEnabled ?? false;
      _queueSize = queueSize;
      _lastSync = persisted?.lastSyncAt.toIso8601String() ?? 'None';
      _syncStatus = persisted != null ? 'S:${persisted.succeeded} F:${persisted.failed} C:${persisted.canceled}' : 'No data';
    });
  }

  Future<void> _loadLanguage() async {
    final stored = await _preferences.getLanguageCode();
    setState(() {
      _language = stored ?? 'en';
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
    setState(() {
      _language = languageCode;
    });
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _setBiometricEnabled(bool enabled) async {
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    final success = await authRepository.setBiometricEnabled(enabled);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to update biometric settings')));
      return;
    }
    setState(() {
      _biometricEnabled = enabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? 'Biometric login enabled' : 'Biometric login disabled')));
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizer.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text(localizer.language),
            subtitle: Text(_language == 'ar' ? localizer.arabic : localizer.english),
          ),
          RadioListTile<String>(
            title: Text(localizer.english),
            value: 'en',
            groupValue: _language,
            onChanged: (value) {
              if (value != null) _setLanguage(value);
            },
          ),
          RadioListTile<String>(
            title: Text(localizer.arabic),
            value: 'ar',
            groupValue: _language,
            onChanged: (value) {
              if (value != null) _setLanguage(value);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(localizer.pushNotifications),
            value: _pushNotificationsEnabled,
            onChanged: (value) => _setPushNotificationsEnabled(value),
            secondary: const Icon(Icons.notifications_active),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              title: Text(localizer.biometricLogin),
              subtitle: Text(_biometricEnabled ? localizer.biometricEnabled : localizer.biometricDisabled),
              value: _biometricEnabled,
              onChanged: (value) => _setBiometricEnabled(value),
              secondary: const Icon(Icons.fingerprint),
            ),
          const SizedBox(height: 24),
          ListTile,
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

