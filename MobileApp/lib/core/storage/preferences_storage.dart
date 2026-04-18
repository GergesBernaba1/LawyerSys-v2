import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStorage {
  static const _languageKey = 'languageCode';
  static const _pushNotificationEnabledKey = 'pushNotificationEnabled';

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> setPushNotificationEnabled(bool enabled) async {
    await setBool(_pushNotificationEnabledKey, enabled);
  }

  Future<bool> getPushNotificationEnabled() async {
    final stored = await getBool(_pushNotificationEnabledKey);
    return stored ?? true;
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setLanguageCode(String languageCode) async {
    await setString(_languageKey, languageCode);
  }

  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
}
