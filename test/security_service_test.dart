import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/security_service.dart';

void main() {
  group('SecurityService', () {
    test('isDeviceSecure returns true when no detection plugin', () async {
      final service = SecurityService();
      // When plugin is not available, should fail open (return true)
      final result = await service.isDeviceSecure();
      expect(result, isTrue);
    });

    test('isDeviceCompromised returns opposite of isDeviceSecure', () async {
      final service = SecurityService();
      final secure = await service.isDeviceSecure();
      final compromised = await service.isDeviceCompromised();
      expect(compromised, isNot(secure));
    });
  });
}
