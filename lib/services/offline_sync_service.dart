import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

/// Manages the offline punch queue using a local SQLite database (Drift).
/// Replaces the old SharedPreferences-based implementation.
class OfflineSyncService {
  final AppDatabase _db;
  final Logger _logger = Logger();
  static const _uuid = Uuid();

  OfflineSyncService(this._db);

  /// Generate a new client-side UUID for idempotency.
  static String generatePunchId() => _uuid.v4();

  /// Save a punch to the offline queue.
  /// [punchData] must include all fields required for a punch request.
  /// [clientPunchId] should be generated before attempting the API call.
  Future<void> saveOfflinePunch(
    Map<String, dynamic> punchData, {
    required String clientPunchId,
  }) async {
    await _db.insertOfflinePunch(
      OfflinePunchesCompanion.insert(
        clientPunchId: clientPunchId,
        employeeId: punchData['employee_id'] as String,
        deviceUuid: punchData['device_uuid'] as String,
        latitude: punchData['latitude'] as double,
        longitude: punchData['longitude'] as double,
        isMockLocation: Value(punchData['is_mock_location'] as bool? ?? false),
        biometricVerified: Value(punchData['biometric_verified'] as bool? ?? true),
        punchType: punchData['punch_type'] as String,
        timestamp: punchData['timestamp'] as String,
        tzOffsetMinutes: Value(punchData['tz_offset_minutes'] as int? ?? 420),
        gpsTimeValidated: Value(punchData['gps_time_validated'] as bool? ?? false),
        syncStatus: const Value('pending'),
      ),
    );

    // Also add to history immediately so user can see pending punch
    await _db.upsertHistory(
      PunchHistoryCompanion.insert(
        clientPunchId: clientPunchId,
        employeeId: punchData['employee_id'] as String,
        punchType: punchData['punch_type'] as String,
        timestamp: punchData['timestamp'] as String,
        syncStatus: punchData['sync_status'] as String? ?? 'pending',
      ),
    );

    final count = await _db.getPendingCount();
    _logger.i('Saved punch to offline queue. Total pending: $count');
  }

  /// Get all punches ready to be retried (pending or failed, retry < 10).
  Future<List<OfflinePunche>> getPendingPunches() => _db.getPendingSyncs();

  /// Number of punches waiting to sync (for UI badge).
  Future<int> getPendingCount() => _db.getPendingCount();

  /// Mark a punch as successfully synced.
  Future<void> markSynced(int id, int serverLogId) async {
    await _db.markSynced(id, serverLogId);
    _logger.i('Punch $id synced successfully (server log_id: $serverLogId)');
  }

  /// Mark a punch as failed and increment retry counter.
  /// After 10 retries it becomes `failed_permanent`.
  Future<void> markFailed(int id, String error) async {
    await _db.incrementRetryAndFail(id, error);
    _logger.w('Punch $id failed: $error');
  }

  /// Flag punches older than 24h as expired for admin review.
  /// Should be called at the start of each sync sweep.
  Future<void> flagExpiredPunches() async {
    await _db.flagExpiredPunches();
    _logger.i('Checked for expired punches (>24h old)');
  }

  /// Get punch history for the history screen.
  Future<List<PunchHistoryData>> getPunchHistory({int limit = 50}) =>
      _db.getRecentHistory(limit: limit);

  /// Save branch config locally for offline operation.
  Future<void> cacheConfig(Map<String, dynamic> config) async {
    await _db.saveCachedConfig(
      CachedConfigCompanion.insert(
        branchName: config['branch_name'] as String? ?? '',
        latitude: config['latitude'] as double? ?? 0.0,
        longitude: config['longitude'] as double? ?? 0.0,
        radiusMeters: config['radius_meters'] as double? ?? 100.0,
        registrationStatus: Value(config['status'] as String? ?? 'pending'),
      ),
    );
  }

  /// Get the last cached config (used when offline).
  Future<CachedConfigData?> getCachedConfig() => _db.getCachedConfig();

  /// Save punch types fetched from server.
  Future<void> cachePunchTypes(List<Map<String, dynamic>> types) async {
    await _db.savePunchTypes(
      types.map((t) => CachedPunchTypesCompanion.insert(
        code: t['code'] as String,
        label: t['label'] as String,
        colorHex: Value(t['color_hex'] as String? ?? '#009CA6'),
        icon: Value(t['icon'] as String? ?? 'schedule'),
        displayOrder: Value(t['display_order'] as int? ?? 0),
        requiresGeofence: Value(t['requires_geofence'] as bool? ?? true),
      )).toList(),
    );
  }

  /// Get cached punch types, or default In/Out if none cached.
  Future<List<Map<String, dynamic>>> getPunchTypes() async {
    final cached = await _db.getCachedPunchTypes();
    if (cached.isEmpty) {
      return [
        {'code': 'In', 'label': 'Clock In', 'color_hex': '#16a34a', 'icon': 'login', 'display_order': 0},
        {'code': 'Out', 'label': 'Clock Out', 'color_hex': '#dc2626', 'icon': 'logout', 'display_order': 1},
      ];
    }
    return cached.map((t) => {
      'code': t.code,
      'label': t.label,
      'color_hex': t.colorHex,
      'icon': t.icon,
      'display_order': t.displayOrder,
      'requires_geofence': t.requiresGeofence,
    }).toList();
  }
}
