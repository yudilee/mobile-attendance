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

/// Represents current day's punch status for the active employee
class TodayAttendanceStatus {
  final bool isClockedIn;
  final String? lastPunchTime;
  final String nextSuggestedPunchType; // 'in' or 'out'
  final String nextSuggestedPunchLabel; // 'Clock In' or 'Clock Out'

  TodayAttendanceStatus({
    required this.isClockedIn,
    this.lastPunchTime,
    required this.nextSuggestedPunchType,
    required this.nextSuggestedPunchLabel,
  });
}

final todayAttendanceStatusProvider = StreamProvider<TodayAttendanceStatus>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.punchHistory)
    ..orderBy([(h) => OrderingTerm.desc(h.createdAt)])
    ..limit(1))
  .watch()
  .map((list) {
    if (list.isEmpty) {
      return TodayAttendanceStatus(
        isClockedIn: false,
        lastPunchTime: null,
        nextSuggestedPunchType: 'in',
        nextSuggestedPunchLabel: 'Clock In',
      );
    }
    final latest = list.first;
    final now = DateTime.now();
    final isToday = latest.createdAt.year == now.year &&
                    latest.createdAt.month == now.month &&
                    latest.createdAt.day == now.day;
    
    if (!isToday) {
      return TodayAttendanceStatus(
        isClockedIn: false,
        lastPunchTime: null,
        nextSuggestedPunchType: 'in',
        nextSuggestedPunchLabel: 'Clock In',
      );
    }

    final pType = latest.punchType.toLowerCase();
    final isCurrentlyIn = pType == 'in' || pType == 'check in';
    
    return TodayAttendanceStatus(
      isClockedIn: isCurrentlyIn,
      lastPunchTime: latest.timestamp,
      nextSuggestedPunchType: isCurrentlyIn ? 'out' : 'in',
      nextSuggestedPunchLabel: isCurrentlyIn ? 'Clock Out' : 'Clock In',
    );
  });
});

// ─── Punch State ──────────────────────────────────────────────────────────────

enum PunchStatus { idle, loading, success, offline, error, qrRequired, selfieRequired, nfcRequired }

class PunchState {
  final PunchStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? result;
  final bool savedOffline;
  final bool qrRequired;
  final bool qrVerified;
  final String? expectedQrData;
  final bool nfcRequired;
  final bool nfcVerified;
  final String? expectedNfcTagData;
  final bool selfieRequired;
  final bool selfieCaptured;
  final String? selfieBase64;
  final DateTime? lastBiometricAuthTime;
  final int biometricSessionSeconds;

  PunchState({
    required this.status,
    this.errorMessage,
    this.result,
    this.savedOffline = false,
    this.qrRequired = false,
    this.qrVerified = false,
    this.expectedQrData,
    this.nfcRequired = false,
    this.nfcVerified = false,
    this.expectedNfcTagData,
    this.selfieRequired = false,
    this.selfieCaptured = false,
    this.selfieBase64,
    this.lastBiometricAuthTime,
    this.biometricSessionSeconds = 0,
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
    bool? nfcRequired,
    bool? nfcVerified,
    String? expectedNfcTagData,
    bool? selfieRequired,
    bool? selfieCaptured,
    String? selfieBase64,
    DateTime? lastBiometricAuthTime,
    int? biometricSessionSeconds,
  }) {
    return PunchState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      savedOffline: savedOffline ?? this.savedOffline,
      qrRequired: qrRequired ?? this.qrRequired,
      qrVerified: qrVerified ?? this.qrVerified,
      expectedQrData: expectedQrData ?? this.expectedQrData,
      nfcRequired: nfcRequired ?? this.nfcRequired,
      nfcVerified: nfcVerified ?? this.nfcVerified,
      expectedNfcTagData: expectedNfcTagData ?? this.expectedNfcTagData,
      selfieRequired: selfieRequired ?? this.selfieRequired,
      selfieCaptured: selfieCaptured ?? this.selfieCaptured,
      selfieBase64: selfieBase64 ?? this.selfieBase64,
      lastBiometricAuthTime: lastBiometricAuthTime ?? this.lastBiometricAuthTime,
      biometricSessionSeconds: biometricSessionSeconds ?? this.biometricSessionSeconds,
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

  /// Expected NFC tag data extracted from device config (set externally).
  String? _expectedNfcTagData;

  /// The last punch type used (for QR/NFC retry).
  String? _lastPunchType;

  /// The last employee ID used (for QR/NFC retry).
  String? _lastEmployeeId;

  /// The captured selfie base64 (set from SelfieScreen).
  String? _selfieBase64;

  PunchNotifier(this._api, this._security, this._offlineSync)
      : super(PunchState.initial());

  /// Set the expected QR code data (called from UI before performPunch).
  void setExpectedQrData(String? data) {
    _expectedQrData = data;
  }

  /// Set the expected NFC tag data (called from UI before performPunch).
  void setExpectedNfcTagData(String? data) {
    _expectedNfcTagData = data;
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
      final sessionSeconds = await _security.getBiometricSessionSeconds();
      state = state.copyWith(
        lastBiometricAuthTime: _lastBiometricAuthTime,
        biometricSessionSeconds: sessionSeconds,
      );
    }
    return authed;
  }

  /// Mark QR as verified and allow punch to proceed.
  void markQRVerified() {
    state = state.copyWith(qrVerified: true, status: PunchStatus.idle);
  }

  /// Mark NFC as verified and allow punch to proceed.
  void markNfcVerified() {
    state = state.copyWith(nfcVerified: true, status: PunchStatus.idle);
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

  /// Reset NFC state (e.g., on cancel).
  void resetNfcState() {
    state = state.copyWith(
      nfcRequired: false,
      nfcVerified: false,
      expectedNfcTagData: null,
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

      // ── Step B.6: NFC tag verification (if required) ─────────────────────
      // Uses `_expectedNfcTagData` set externally via `setExpectedNfcTagData()` from UI.
      final nfcEnabled = await AppSettings.getNFCEnabled();
      if (nfcEnabled && !state.nfcVerified && _expectedNfcTagData != null && _expectedNfcTagData!.isNotEmpty) {
        state = state.copyWith(
          status: PunchStatus.nfcRequired,
          nfcRequired: true,
          expectedNfcTagData: _expectedNfcTagData,
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
      Map<String, dynamic> response;
      try {
        response = await _api.submitPunch(
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
      } catch (submitError) {
        if (submitError.toString().toLowerCase().contains('duplicate')) {
          // If it's a duplicate, the server already recorded a punch successfully!
          // We treat this as a success so the local UI updates.
          response = {
            'status': 'duplicate',
            'message': submitError.toString().replaceFirst('Exception: ', ''),
            'log_id': null,
          };
        } else {
          rethrow;
        }
      }

      // ── Record to local history so dashboard/history screen reflects it ──
      final serverLogId = response['log_id'] as int?;
      await _offlineSync.recordSyncedPunch(
        clientPunchId: clientPunchId,
        employeeId: employeeId,
        punchType: punchType,
        timestamp: timeResult.isoString,
        serverLogId: serverLogId,
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

  final serverUrl = await AppSettings.getServerUrl();
  final apiKey = await AppSettings.getApiKey();
  if (serverUrl.isEmpty || apiKey.isEmpty) {
    throw Exception(
      'Device not configured yet. Please configure Server URL and API Key in Settings.',
    );
  }

  final employeeId = await AppSettings.getEmployeeId();
  final uuid = await security.getDeviceUniqueId();

  try {
    final config = await api.getDeviceConfig(
      employeeId: employeeId.isNotEmpty ? employeeId : null,
      deviceUuid: uuid,
    );
    // Cache config for offline use
    await offlineSync.cacheConfig(config);

    final empId = config['employee_id'] as String?;
    if (empId != null && empId.isNotEmpty) {
      await AppSettings.setEmployeeId(empId);
    }

    final empName = config['employee_name'] as String?;
    if (empName != null && empName.isNotEmpty) {
      await AppSettings.setEmployeeName(empName);
    }

    // Also fetch and cache punch types
    try {
      final punchTypes = await api.getPunchTypes();
      await offlineSync.cachePunchTypes(punchTypes);
    } catch (e) {
      // Ignore punch types fetch failure to not break config flow
    }
    
    return config;
  } on AuthenticationException catch (e) {
    return {
      'status': 'auth_error',
      'message': e.message.isNotEmpty ? e.message : 'Invalid or expired API Key. Please re-scan QR in Settings.',
    };
  } on ForbiddenException catch (e) {
    return {
      'status': 'forbidden',
      'message': e.message.isNotEmpty ? e.message : 'Device suspended or deactivated by admin.',
    };
  } on NetworkException catch (e) {
    // Network failed — try cached config ONLY if previously approved and active
    final cached = await offlineSync.getCachedConfig();
    if (cached != null && (cached.registrationStatus == 'active' || cached.registrationStatus == 'approved')) {
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
    return {
      'status': 'offline',
      'message': 'Offline mode: Unable to connect to server ($e).',
    };
  } catch (e) {
    // General error
    return {
      'status': 'error',
      'message': e.toString().replaceAll('Exception: ', ''),
    };
  }
});

// ─── Pending Count Provider (for badge) ──────────────────────────────────────

final pendingPunchCountProvider = FutureProvider<int>((ref) async {
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return offlineSync.getPendingCount();
});

// Stream of offline punches in queue (not successfully synced yet)
final offlineQueueProvider = StreamProvider<List<OfflinePunche>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.offlinePunches)
        ..where((p) => p.syncStatus.isIn(['pending', 'failed', 'failed_permanent', 'expired_pending_review']))
        ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
      .watch();
});

