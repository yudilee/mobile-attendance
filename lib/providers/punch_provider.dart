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

enum PunchStatus { idle, loading, success, offline, error, qrRequired, selfieRequired }

class PunchState {
  final PunchStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? result;
  final bool savedOffline;
  final bool qrRequired;
  final bool qrVerified;
  final String? expectedQrData;
  final bool selfieRequired;
  final bool selfieCaptured;
  final String? selfieBase64;

  PunchState({
    required this.status,
    this.errorMessage,
    this.result,
    this.savedOffline = false,
    this.qrRequired = false,
    this.qrVerified = false,
    this.expectedQrData,
    this.selfieRequired = false,
    this.selfieCaptured = false,
    this.selfieBase64,
  });

  factory PunchState.initial() => PunchState(status: PunchStatus.idle);

  PunchState copyWith({
    PunchStatus? status,
    String? errorMessage,
    Map<String, dynamic>? result,
    bool? savedOffline,
    bool? qrRequired,
    bool? qrVerified,
    String? expectedQrData,
    bool? selfieRequired,
    bool? selfieCaptured,
    String? selfieBase64,
  }) {
    return PunchState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      savedOffline: savedOffline ?? this.savedOffline,
      qrRequired: qrRequired ?? this.qrRequired,
      qrVerified: qrVerified ?? this.qrVerified,
      expectedQrData: expectedQrData ?? this.expectedQrData,
      selfieRequired: selfieRequired ?? this.selfieRequired,
      selfieCaptured: selfieCaptured ?? this.selfieCaptured,
      selfieBase64: selfieBase64 ?? this.selfieBase64,
    );
  }
}

// ─── Punch Notifier ────────────────────────────────────────────────────────────

class PunchNotifier extends StateNotifier<PunchState> {
  final ApiService _api;
  final SecurityService _security;
  final OfflineSyncService _offlineSync;

  /// Timestamp of the last successful biometric authentication, used for session management.
  DateTime? _lastBiometricAuthTime;

  /// Expected QR data extracted from device config (set externally).
  String? _expectedQrData;

  /// The last punch type used (for QR retry).
  String? _lastPunchType;

  /// The last employee ID used (for QR retry).
  String? _lastEmployeeId;

  /// The captured selfie base64 (set from SelfieScreen).
  String? _selfieBase64;

  PunchNotifier(this._api, this._security, this._offlineSync)
      : super(PunchState.initial());

  /// Set the expected QR code data (called from UI before performPunch).
  void setExpectedQrData(String? data) {
    _expectedQrData = data;
  }

  /// Checks if the prior biometric authentication is still valid within the session window.
  Future<bool> _isBiometricSessionValid() async {
    if (_lastBiometricAuthTime == null) return false;
    final sessionSeconds = await _security.getBiometricSessionSeconds();
    if (sessionSeconds <= 0) return false; // Every punch requires auth
    final elapsed = DateTime.now().difference(_lastBiometricAuthTime!);
    return elapsed.inSeconds < sessionSeconds;
  }

  /// Requires biometric authentication unless a valid session already exists.
  Future<bool> _requireBiometricWithSession() async {
    if (await _isBiometricSessionValid()) {
      return true; // Reuse existing session
    }
    // Otherwise, require fresh biometric auth
    final authed = await _security.authenticateBiometrics();
    if (authed) {
      _lastBiometricAuthTime = DateTime.now();
    }
    return authed;
  }

  /// Mark QR as verified and allow punch to proceed.
  void markQRVerified() {
    state = state.copyWith(qrVerified: true, status: PunchStatus.idle);
  }

  /// Mark selfie as captured and allow punch to proceed.
  void setSelfieBase64(String base64) {
    _selfieBase64 = base64;
    state = state.copyWith(
      selfieBase64: base64,
      selfieCaptured: true,
      status: PunchStatus.idle,
    );
  }

  /// Reset QR state (e.g., on cancel).
  void resetQRState() {
    state = state.copyWith(
      qrRequired: false,
      qrVerified: false,
      expectedQrData: null,
      status: PunchStatus.idle,
    );
  }

  Future<void> performPunch(String employeeId, String punchType) async {
    state = PunchState(status: PunchStatus.loading);

    // Declared here so the NetworkException handler can reuse them
    Map<String, dynamic>? punchPayload;

    try {
      // Store punch type and employee ID for potential QR retry
      _lastPunchType = punchType;
      _lastEmployeeId = employeeId;

      // ── Step A: Root / Jailbreak check ────────────────────────────────────
      final isCompromised = await _security.isDeviceCompromised();
      if (isCompromised) {
        throw Exception(
          'This device appears to be rooted/jailbroken. Punching is not allowed on compromised devices.',
        );
      }

      // ── Step B: Biometric / device auth (with session) ────────────────────
      final authed = await _requireBiometricWithSession();
      if (!authed) {
        throw Exception(
          'Authentication cancelled. Please verify your identity to record attendance.',
        );
      }
      final biometricVerified = true; // Auth succeeded at this point

      // ── Step B.5: QR code verification (if required) ─────────────────────
      // Uses `_expectedQrData` set externally via `setExpectedQrData()` from UI.
      final qrEnabled = await AppSettings.getQREnabled();
      if (qrEnabled && !state.qrVerified && _expectedQrData != null && _expectedQrData!.isNotEmpty) {
        state = state.copyWith(
          status: PunchStatus.qrRequired,
          qrRequired: true,
          expectedQrData: _expectedQrData,
        );
        return;
      }

      // ── Step C: Hardware identity ─────────────────────────────────────────
      final uuid = await _security.getDeviceUniqueId();

      // ── Step D: Geolocation & anti-spoofing ──────────────────────────────
      final position = await _security.getCurrentValidatedLocation();
      if (position == null) {
        throw Exception('Could not get location. Enable GPS and try again.');
      }
      if (position.isMocked) {
        throw Exception('Security Alert: Mock/fake location detected. Punch rejected.');
      }

      // ── Step E: GPS-validated timestamp ───────────────────────────────────
      final timeResult = await _security.getReliableTimestamp(gpsPosition: position);

      // ── Step E.5: Selfie / Face Verification ─────────────────────────────
      final selfieEnabled = await AppSettings.getSelfieEnabled();
      if (selfieEnabled && (_selfieBase64 == null || _selfieBase64!.isEmpty)) {
        state = state.copyWith(
          status: PunchStatus.selfieRequired,
          selfieRequired: true,
        );
        return;
      }

      // ── Step F: Generate idempotency ID & build payload ───────────────────
      final clientPunchId = OfflineSyncService.generatePunchId();
      punchPayload = {
        'employee_id': employeeId,
        'device_uuid': uuid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'is_mock_location': position.isMocked,
        'biometric_verified': biometricVerified,
        'punch_type': punchType,
        'timestamp': timeResult.isoString,
        'selfie_base64': _selfieBase64,
        'tz_offset_minutes': timeResult.tzOffsetMinutes,
        'gps_time_validated': timeResult.gpsValidated,
        'client_punch_id': clientPunchId,
      };

      // ── Step G: Submit to server ──────────────────────────────────────────
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
      if (punchPayload != null) {
        // Reuse the exact payload captured at punch moment — no re-fetching
        try {
          await _offlineSync.saveOfflinePunch(
            punchPayload,
            clientPunchId: punchPayload['client_punch_id'] as String,
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
      } else {
        state = PunchState(
          status: PunchStatus.error,
          errorMessage: 'Network unavailable. Please try again.',
        );
      }
    } catch (e) {
      state = PunchState(status: PunchStatus.error, errorMessage: e.toString());
    }
  }

  /// Retry the last punch after QR verification succeeded.
  void retryWithQR() {
    if (_lastEmployeeId != null && _lastPunchType != null) {
      performPunch(_lastEmployeeId!, _lastPunchType!);
    }
  }

  void reset() {
    _selfieBase64 = null;
    state = PunchState.initial();
  }
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
      final branches = await offlineSync.getCachedBranches();
      return {
        'status': cached.registrationStatus,
        'branches': branches,
        'branch_name': cached.branchName,
        'latitude': cached.latitude,
        'longitude': cached.longitude,
        'radius_meters': cached.radiusMeters,
        'device_count': branches.isNotEmpty ? 1 : 0,
        'max_devices': 5,
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
