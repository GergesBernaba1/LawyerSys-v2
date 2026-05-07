import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/preferences_storage.dart';

/// Cubit for managing app theme mode
class ThemeCubit extends Cubit<ThemeMode> {
  final PreferencesStorage _prefsStorage;
  static const String _themeModeKey = 'theme_mode';

  ThemeCubit(this._prefsStorage) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load saved theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final savedMode = await _prefsStorage.getString(_themeModeKey);
      if (savedMode != null) {
        emit(_themeModeFromString(savedMode));
      } else {
        emit(ThemeMode.system);
      }
    } catch (e) {
      emit(ThemeMode.system);
    }
  }

  /// Set theme mode to light
  Future<void> setLightMode() async {
    emit(ThemeMode.light);
    await _prefsStorage.setString(_themeModeKey, 'light');
  }

  /// Set theme mode to dark
  Future<void> setDarkMode() async {
    emit(ThemeMode.dark);
    await _prefsStorage.setString(_themeModeKey, 'dark');
  }

  /// Set theme mode to system default
  Future<void> setSystemMode() async {
    emit(ThemeMode.system);
    await _prefsStorage.setString(_themeModeKey, 'system');
  }

  /// Toggle between light and dark modes
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  /// Convert string to ThemeMode
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Get current theme mode as string
  String get themeModeString {
    switch (state) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;
    
    // System mode - check device brightness
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
