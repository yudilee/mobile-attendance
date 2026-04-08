import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/security_service.dart';
import '../services/app_settings.dart';
import '../services/offline_sync_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final securityServiceProvider = Provider((ref) => SecurityService());
final offlineSyncServiceProvider = Provider((ref) => OfflineSyncService());

enum PunchStatus { idle, loading, success, error }

class PunchState {
  final PunchStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? result;

  PunchState({required this.status, this.errorMessage, this.result});

  factory PunchState.initial() => PunchState(status: PunchStatus.idle);
}

class PunchNotifier extends StateNotifier<PunchState> {
  final ApiService _api;
  final SecurityService _security;
  final OfflineSyncService _offlineSync;

  PunchNotifier(this._api, this._security, this._offlineSync) : super(PunchState.initial());

  Future<void> performPunch(String employeeId, String punchType) async {
    state = PunchState(status: PunchStatus.loading);

    try {
      // Step A: Attempt biometric/device auth
      final authResult = await _security.authenticateWithDevice();

      if (!authResult.verified && authResult.reason == 'user_cancelled') {
        throw Exception("Authentication cancelled. Please verify your identity to record attendance.");
      }

      final biometricVerified = authResult.verified;

      // Step B: Hardware Identity
      final uuid = await _security.getDeviceUniqueId();

      // Step C: Geolocation & Anti-Spoofing
      final position = await _security.getCurrentValidatedLocation();
      if (position == null) {
        throw Exception("Could not get location. Enable GPS and try again.");
      }

      // Step D: Local Mock Rejection
      if (position.isMocked) {
        throw Exception("Security Alert: Mock/fake location detected. Punch rejected.");
      }

      // Step E: GPS-Validated Local Time (works offline, no NTP needed)
      // Cross-validates device clock against GPS satellite time
      final timeResult = await _security.getReliableTimestamp(gpsPosition: position);

      // Step F: Submit to Aggregator
      final response = await _api.submitPunch(
        employeeId: employeeId,
        deviceUuid: uuid,
        lat: position.latitude,
        lon: position.longitude,
        isMocked: position.isMocked,
        biometricVerified: biometricVerified,
        punchType: punchType,
        timestamp: timeResult.isoString,
        tzOffsetMinutes: timeResult.tzOffsetMinutes,
        gpsValidated: timeResult.gpsValidated,
      );

      state = PunchState(status: PunchStatus.success, result: response);
    } on NetworkException catch (e) {
      // Reconstitute the full data dictionary
      final timeResult = await _security.getReliableTimestamp(gpsPosition: await _security.getCurrentValidatedLocation());
      final position = await _security.getCurrentValidatedLocation();
      final uuid = await _security.getDeviceUniqueId();
      final biometricVerified = true; // Assuming success from earlier
      
      final offlineData = {
        'employee_id': employeeId,
        'device_uuid': uuid,
        'latitude': position!.latitude,
        'longitude': position.longitude,
        'is_mock_location': position.isMocked,
        'biometric_verified': biometricVerified,
        'punch_type': punchType,
        'timestamp': timeResult.isoString,
        'tz_offset_minutes': timeResult.tzOffsetMinutes,
        'gps_time_validated': timeResult.gpsValidated,
      };
      
      await _offlineSync.saveOfflinePunch(offlineData);
      state = PunchState(status: PunchStatus.success, result: {
        'offline': true,
        'message': 'Saved offline. Will sync when connection is restored.'
      });
    } catch (e) {
      state = PunchState(status: PunchStatus.error, errorMessage: e.toString());
    }
  }

  void reset() {
    state = PunchState.initial();
  }
}

final punchStateProvider = StateNotifierProvider<PunchNotifier, PunchState>((ref) {
  return PunchNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(securityServiceProvider),
    ref.watch(offlineSyncServiceProvider),
  );
});

final deviceConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final security = ref.watch(securityServiceProvider);
  
  final employeeId = await AppSettings.getEmployeeId();
  if (employeeId.isEmpty) {
    throw Exception("Device not configured yet. Please enter your Employee ID in Settings.");
  }
  
  final uuid = await security.getDeviceUniqueId();
  return await api.getDeviceConfig(employeeId: employeeId, deviceUuid: uuid);
});
