import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'app_settings.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForced;
  final String latestVersion;
  final String minVersion;
  final String currentVersion;
  final String downloadUrl;
  final String changelog;
  final String title;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForced,
    required this.latestVersion,
    required this.minVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.changelog,
    required this.title,
  });

  factory AppUpdateInfo.none({required String currentVersion}) {
    return AppUpdateInfo(
      hasUpdate: false,
      isForced: false,
      latestVersion: currentVersion,
      minVersion: currentVersion,
      currentVersion: currentVersion,
      downloadUrl: '',
      changelog: '',
      title: 'App is up to date',
    );
  }
}

class UpdateService {
  static final _log = Logger();
  static const _keySkippedVersion = 'skipped_update_version';

  /// Fetches version info from server and evaluates update availability.
  static Future<AppUpdateInfo> checkForUpdates({bool isManualCheck = false}) async {
    String currentVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (_) {
      // Fallback
    }

    final serverUrl = await AppSettings.getServerUrl();
    if (serverUrl.isEmpty) {
      return AppUpdateInfo.none(currentVersion: currentVersion);
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Accept': 'application/json'},
        ),
      );

      final cleanUrl = serverUrl.replaceAll(RegExp(r'/+$'), '');
      final res = await dio.get(
        '$cleanUrl/api/v1/app/version-check',
        queryParameters: {'current_version': currentVersion},
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final hasUpdate = data['has_update'] == true;
        final isForced = data['is_forced'] == true;
        final latestVer = data['latest_version']?.toString() ?? currentVersion;
        final minVer = data['min_supported_version']?.toString() ?? '1.0.0';
        final dlUrl = data['download_url']?.toString() ?? '';
        final notes = data['changelog']?.toString() ?? '';
        final title = data['title']?.toString() ?? (isForced ? 'Important Update Required' : 'New Update Available');

        // Check if user previously skipped this version (only applies to non-forced updates during auto-check)
        if (!isManualCheck && !isForced && hasUpdate) {
          final prefs = await SharedPreferences.getInstance();
          final skipped = prefs.getString(_keySkippedVersion);
          if (skipped == latestVer) {
            _log.d('Update $latestVer was previously skipped by user.');
            return AppUpdateInfo.none(currentVersion: currentVersion);
          }
        }

        return AppUpdateInfo(
          hasUpdate: hasUpdate,
          isForced: isForced,
          latestVersion: latestVer,
          minVersion: minVer,
          currentVersion: currentVersion,
          downloadUrl: dlUrl,
          changelog: notes,
          title: title,
        );
      }
    } catch (e) {
      _log.w('Update check request error: $e');
    }

    return AppUpdateInfo.none(currentVersion: currentVersion);
  }

  /// Mark a version as skipped so it doesn't prompt automatically until a newer release.
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySkippedVersion, version);
  }
}
