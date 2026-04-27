import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists user-configurable settings on the device.
/// Sensitive values (API key) use flutter_secure_storage.
class AppSettings {
  static const _keyEmployeeId = 'employee_id';
  static const _keyServerUrl = 'server_url';
  static const _keyDeviceLabel = 'device_label';
  static const _keyApiKey = 'api_key'; // stored in secure storage

  static const defaultServerUrl = 'http://10.0.2.2:8000';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String> getEmployeeId() async =>
      (await _prefs()).getString(_keyEmployeeId) ?? '';

  static Future<void> setEmployeeId(String id) async =>
      (await _prefs()).setString(_keyEmployeeId, id.trim());

  static Future<String> getServerUrl() async =>
      (await _prefs()).getString(_keyServerUrl) ?? defaultServerUrl;

  static Future<void> setServerUrl(String url) async =>
      (await _prefs()).setString(_keyServerUrl, url.trim());

  static Future<String> getDeviceLabel() async =>
      (await _prefs()).getString(_keyDeviceLabel) ?? '';

  static Future<void> setDeviceLabel(String label) async =>
      (await _prefs()).setString(_keyDeviceLabel, label.trim());

  // API key stored in encrypted secure storage
  static Future<String> getApiKey() async =>
      await _secure.read(key: _keyApiKey) ?? '';

  static Future<void> setApiKey(String key) async =>
      _secure.write(key: _keyApiKey, value: key.trim());

  static Future<bool> isConfigured() async {
    final empId = await getEmployeeId();
    return empId.isNotEmpty;
  }
}

