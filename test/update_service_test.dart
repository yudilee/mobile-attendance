import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService Model Tests', () {
    test('AppUpdateInfo.none creates valid fallback instance', () {
      final info = AppUpdateInfo.none(currentVersion: '1.0.0');
      expect(info.hasUpdate, false);
      expect(info.isForced, false);
      expect(info.latestVersion, '1.0.0');
      expect(info.currentVersion, '1.0.0');
      expect(info.downloadUrl, isEmpty);
    });

    test('AppUpdateInfo creates forced update instance correctly', () {
      const info = AppUpdateInfo(
        hasUpdate: true,
        isForced: true,
        latestVersion: '1.1.0',
        minVersion: '1.1.0',
        currentVersion: '1.0.0',
        downloadUrl: 'https://example.com/app.apk',
        changelog: '• Bug fixes',
        title: 'Important Update Required',
      );
      expect(info.hasUpdate, true);
      expect(info.isForced, true);
      expect(info.latestVersion, '1.1.0');
      expect(info.downloadUrl, 'https://example.com/app.apk');
      expect(info.changelog, contains('Bug fixes'));
    });
  });
}
