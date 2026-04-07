import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable settings on the device.
/// Provides defaults that can be overridden from the settings screen.
class AppSettings {
  static const _keyEmployeeId = 'employee_id';
  static const _keyServerUrl = 'server_url';
  static const _keyApiKey = 'api_key';

  // Default values — change server URL to match your deployment
  static const defaultServerUrl = 'http://10.0.2.2:8000';
  static const defaultApiKey = '';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String> getEmployeeId() async {
    final prefs = await _prefs();
    return prefs.getString(_keyEmployeeId) ?? '';
  }

  static Future<void> setEmployeeId(String id) async {
    final prefs = await _prefs();
    await prefs.setString(_keyEmployeeId, id.trim());
  }

  static Future<String> getServerUrl() async {
    final prefs = await _prefs();
    return prefs.getString(_keyServerUrl) ?? defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await _prefs();
    await prefs.setString(_keyServerUrl, url.trim());
  }

  static Future<String> getApiKey() async {
    final prefs = await _prefs();
    return prefs.getString(_keyApiKey) ?? defaultApiKey;
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await _prefs();
    await prefs.setString(_keyApiKey, key.trim());
  }

  static Future<bool> isConfigured() async {
    final empId = await getEmployeeId();
    return empId.isNotEmpty;
  }
}
