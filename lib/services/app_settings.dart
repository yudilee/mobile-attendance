import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists user-configurable settings on the device.
/// Sensitive values (API key) use flutter_secure_storage.
class AppSettings {
  static const _keyEmployeeId = 'employee_id';
  static const _keyServerUrl = 'server_url';
  static const _keyDeviceLabel = 'device_label';
  static const _keyEmployeeName = 'employee_name';
  static const _keyApiKey = 'api_key'; // stored in secure storage
  static const _keyCertificatePinEnabled = 'certificate_pin_enabled';
  static const _keyBiometricSessionSeconds = 'biometric_session_seconds';

  static const defaultServerUrl = 'http://10.0.2.2:8000';
  static const defaultBiometricSessionSeconds = 30;
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String> getEmployeeId() async =>
      (await _prefs()).getString(_keyEmployeeId) ?? '';

  static Future<void> setEmployeeId(String id) async =>
      (await _prefs()).setString(_keyEmployeeId, id.trim());

  static Future<String> getEmployeeName() async =>
      (await _prefs()).getString(_keyEmployeeName) ?? '';

  static Future<void> setEmployeeName(String name) async =>
      (await _prefs()).setString(_keyEmployeeName, name.trim());

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

  // ── Certificate Pinning ──────────────────────────────────────────────────────

  static Future<bool> isCertificatePinEnabled() async =>
      (await _prefs()).getBool(_keyCertificatePinEnabled) ?? false;

  static Future<void> setCertificatePinEnabled(bool enabled) async =>
      (await _prefs()).setBool(_keyCertificatePinEnabled, enabled);

  // ── Biometric Session Duration ───────────────────────────────────────────────

  static Future<int> getBiometricSessionSeconds() async =>
      (await _prefs()).getInt(_keyBiometricSessionSeconds) ?? defaultBiometricSessionSeconds;

  static Future<void> setBiometricSessionSeconds(int seconds) async =>
      (await _prefs()).setInt(_keyBiometricSessionSeconds, seconds);

  // ── QR / NFC Verification Toggles ─────────────────────────────────────────────

  static Future<bool> getQREnabled() async =>
      (await _prefs()).getBool('qr_enabled') ?? false;

  static Future<void> setQREnabled(bool val) async =>
      (await _prefs()).setBool('qr_enabled', val);

  static Future<bool> getNFCEnabled() async =>
      (await _prefs()).getBool('nfc_enabled') ?? false;

  static Future<void> setNFCEnabled(bool val) async =>
      (await _prefs()).setBool('nfc_enabled', val);

  // ── Selfie / Face Verification ──────────────────────────────────────────────

  static Future<bool> getSelfieEnabled() async =>
      (await _prefs()).getBool('selfie_enabled') ?? false;

  static Future<void> setSelfieEnabled(bool val) async =>
      (await _prefs()).setBool('selfie_enabled', val);

  // ── Push Notifications ───────────────────────────────────────────────────────

  static Future<bool> getNotificationsEnabled() async =>
      (await _prefs()).getBool('notifications_enabled') ?? true;

  static Future<void> setNotificationsEnabled(bool val) async =>
      (await _prefs()).setBool('notifications_enabled', val);

  static Future<bool> getReminderNotifications() async =>
      (await _prefs()).getBool('reminder_notifications') ?? true;

  static Future<void> setReminderNotifications(bool val) async =>
      (await _prefs()).setBool('reminder_notifications', val);

  static Future<bool> isConfigured() async {
    final serverUrl = await getServerUrl();
    final apiKey = await getApiKey();
    return serverUrl.isNotEmpty && apiKey.isNotEmpty;
  }

  /// Returns a list of human-readable reasons why the app is not configured.
  static Future<List<String>> configurationGaps() async {
    final gaps = <String>[];
    if ((await getServerUrl()).isEmpty) gaps.add('Server URL');
    if ((await getApiKey()).isEmpty) gaps.add('API Key');
    return gaps;
  }
}

