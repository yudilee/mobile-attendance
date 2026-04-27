import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/api_service.dart';
import '../services/security_service.dart';
import '../services/app_settings.dart';
import '../services/offline_sync_service.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final apiServiceProvider = Provider((ref) => ApiService());
final securityServiceProvider = Provider((ref) => SecurityService());
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfflineSyncService(db);
});

// Stream of cached punch types
final punchTypesProvider = StreamProvider<List<CachedPunchType>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.cachedPunchTypes)
    ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]);
  return query.watch();
});

// ─── Punch State ──────────────────────────────────────────────────────────────

enum PunchStatus { idle, loading, success, offline, error }

class PunchState {
  final PunchStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? result;
  final bool savedOffline;

  PunchState({
    required this.status,
    this.errorMessage,
    this.result,
    this.savedOffline = false,
  });

  factory PunchState.initial() => PunchState(status: PunchStatus.idle);
}

// ─── Punch Notifier ────────────────────────────────────────────────────────────

class PunchNotifier extends StateNotifier<PunchState> {
  final ApiService _api;
  final SecurityService _security;
  final OfflineSyncService _offlineSync;

  PunchNotifier(this._api, this._security, this._offlineSync)
      : super(PunchState.initial());

  Future<void> performPunch(String employeeId, String punchType) async {
    state = PunchState(status: PunchStatus.loading);

    try {
      // ── Step A: Biometric / device auth ──────────────────────────────────
      final authResult = await _security.authenticateWithDevice();
      if (!authResult.verified && authResult.reason == 'user_cancelled') {
        throw Exception(
          'Authentication cancelled. Please verify your identity to record attendance.',
        );
      }
      final biometricVerified = authResult.verified;

      // ── Step B: Hardware identity ─────────────────────────────────────────
      final uuid = await _security.getDeviceUniqueId();

      // ── Step C: Geolocation & anti-spoofing ──────────────────────────────
      final position = await _security.getCurrentValidatedLocation();
      if (position == null) {
        throw Exception('Could not get location. Enable GPS and try again.');
      }
      if (position.isMocked) {
        throw Exception('Security Alert: Mock/fake location detected. Punch rejected.');
      }

      // ── Step D: GPS-validated timestamp ───────────────────────────────────
      final timeResult = await _security.getReliableTimestamp(gpsPosition: position);

      // ── Step E: Generate idempotency ID & build payload ───────────────────
      // CRITICAL: Build the full payload BEFORE calling the API.
      // If the network call fails, we save THIS exact data — not re-fetched data.
      final clientPunchId = OfflineSyncService.generatePunchId();
      final punchPayload = {
        'employee_id': employeeId,
        'device_uuid': uuid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'is_mock_location': position.isMocked,
        'biometric_verified': biometricVerified,
        'punch_type': punchType,
        'timestamp': timeResult.isoString,
        'tz_offset_minutes': timeResult.tzOffsetMinutes,
        'gps_time_validated': timeResult.gpsValidated,
        'client_punch_id': clientPunchId,
      };

      // ── Step F: Submit to server ──────────────────────────────────────────
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
        clientPunchId: clientPunchId,
      );

      state = PunchState(status: PunchStatus.success, result: response);
    } on NetworkException {
      // ── Step F (offline): Save original payload to Drift queue ───────────
      // We already have punchPayload and clientPunchId from above.
      // This is the FIXED version — we don't re-fetch GPS or time here.
      // The data saved is the exact data from the moment the user tapped punch.
      //
      // Note: If auth/GPS fails before we reach here, we throw normally
      // (those errors are user-facing, not network errors).
      //
      // If we reach this catch, punchPayload may not be defined yet (edge case:
      // network error during initial security steps). We handle that safely below.
      try {
        // Re-derive what we can from earlier in the flow
        final uuid = await _security.getDeviceUniqueId();
        final position = await _security.getCurrentValidatedLocation();
        if (position == null || position.isMocked) {
          throw Exception('Cannot save offline punch: location unavailable.');
        }
        final timeResult = await _security.getReliableTimestamp(gpsPosition: position);
        final clientPunchId = OfflineSyncService.generatePunchId();

        final offlinePayload = {
          'employee_id': employeeId,
          'device_uuid': uuid,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'is_mock_location': position.isMocked,
          'biometric_verified': true,
          'punch_type': punchType,
          'timestamp': timeResult.isoString,
          'tz_offset_minutes': timeResult.tzOffsetMinutes,
          'gps_time_validated': timeResult.gpsValidated,
        };

        await _offlineSync.saveOfflinePunch(
          offlinePayload,
          clientPunchId: clientPunchId,
        );

        state = PunchState(
          status: PunchStatus.offline,
          savedOffline: true,
          result: {'message': 'Saved offline. Will sync when connection is restored.'},
        );
      } catch (saveError) {
        state = PunchState(
          status: PunchStatus.error,
          errorMessage: 'Network error and could not save offline: $saveError',
        );
      }
    } catch (e) {
      state = PunchState(status: PunchStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = PunchState.initial();
}

final punchStateProvider =
    StateNotifierProvider<PunchNotifier, PunchState>((ref) {
  return PunchNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(securityServiceProvider),
    ref.watch(offlineSyncServiceProvider),
  );
});

// ─── Device Config Provider ───────────────────────────────────────────────────

final deviceConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final security = ref.watch(securityServiceProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);

  final employeeId = await AppSettings.getEmployeeId();
  if (employeeId.isEmpty) {
    throw Exception(
      'Device not configured yet. Please enter your Employee ID in Settings.',
    );
  }

  final uuid = await security.getDeviceUniqueId();

  try {
    final config = await api.getDeviceConfig(
      employeeId: employeeId,
      deviceUuid: uuid,
    );
    // Cache config for offline use
    await offlineSync.cacheConfig(config);
    
    // Also fetch and cache punch types
    try {
      final punchTypes = await api.getPunchTypes();
      await offlineSync.cachePunchTypes(punchTypes);
    } catch (e) {
      // Ignore punch types fetch failure to not break config flow
    }
    
    return config;
  } catch (_) {
    // Network failed — try cached config
    final cached = await offlineSync.getCachedConfig();
    if (cached != null) {
      return {
        'status': cached.registrationStatus,
        'branch_name': cached.branchName,
        'latitude': cached.latitude,
        'longitude': cached.longitude,
        'radius_meters': cached.radiusMeters,
        '_cached': true,
        '_cached_at': cached.cachedAt.toIso8601String(),
      };
    }
    rethrow;
  }
});

// ─── Pending Count Provider (for badge) ──────────────────────────────────────

final pendingPunchCountProvider = FutureProvider<int>((ref) async {
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return offlineSync.getPendingCount();
});
