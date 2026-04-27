import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Table Definitions ────────────────────────────────────────────────────────

/// Queue of punches that failed to sync due to network issues.
/// Replaces the old SharedPreferences JSON list.
class OfflinePunches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientPunchId => text()(); // UUID for idempotency
  TextColumn get employeeId => text()();
  TextColumn get deviceUuid => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  BoolColumn get isMockLocation => boolean().withDefault(const Constant(false))();
  BoolColumn get biometricVerified => boolean().withDefault(const Constant(true))();
  TextColumn get punchType => text()(); // "In" | "Out" | future types
  TextColumn get timestamp => text()(); // ISO 8601 local time string
  IntColumn get tzOffsetMinutes => integer().withDefault(const Constant(420))();
  BoolColumn get gpsTimeValidated => boolean().withDefault(const Constant(false))();

  // Sync tracking
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  // pending | syncing | synced | failed | expired_pending_review
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get serverLogId => integer().nullable()(); // returned by server after sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// Local read-only log for the punch history screen.
/// Populated after successful sync (or immediately for offline punches).
class PunchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientPunchId => text()();
  TextColumn get employeeId => text()();
  TextColumn get punchType => text()();
  TextColumn get timestamp => text()(); // display string
  TextColumn get syncStatus => text()(); // "synced" | "pending" | "expired"
  IntColumn get serverLogId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cached branch/geofence config so the app works offline.
class CachedConfig extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get branchName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radiusMeters => real()();
  TextColumn get registrationStatus => text().withDefault(const Constant('pending'))();
  // pending_approval | pending_branch | active | suspended
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cached list of punch types fetched from server.
class CachedPunchTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text()(); // "In", "Out", "Break_Start"
  TextColumn get label => text()(); // "Clock In", "Clock Out"
  TextColumn get colorHex => text().withDefault(const Constant('#009CA6'))();
  TextColumn get icon => text().withDefault(const Constant('schedule'))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get requiresGeofence => boolean().withDefault(const Constant(true))();
}

// ─── Database Class ────────────────────────────────────────────────────────────

@DriftDatabase(tables: [OfflinePunches, PunchHistory, CachedConfig, CachedPunchTypes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Offline Punch Queue ────────────────────────────────────────────────────

  Future<int> insertOfflinePunch(OfflinePunchesCompanion punch) =>
      into(offlinePunches).insert(punch);

  /// Get all punches ready to be synced (not already syncing/synced/expired).
  Future<List<OfflinePunche>> getPendingSyncs() => (select(offlinePunches)
        ..where((p) => p.syncStatus.isIn(['pending', 'failed']))
        ..where((p) => p.retryCount.isSmallerOrEqualValue(10))
        ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
      .get();

  Future<int> getPendingCount() async {
    final result = await (select(offlinePunches)
          ..where((p) => p.syncStatus.isIn(['pending', 'failed']))
          ..where((p) => p.retryCount.isSmallerOrEqualValue(10)))
        .get();
    return result.length;
  }

  Future<void> markSynced(int id, int serverLogId) async {
    // Get the clientPunchId first, then update history
    final punch = await (select(offlinePunches)..where((p) => p.id.equals(id))).getSingleOrNull();
    await (update(offlinePunches)..where((p) => p.id.equals(id))).write(
      OfflinePunchesCompanion(
        syncStatus: const Value('synced'),
        serverLogId: Value(serverLogId),
        syncedAt: Value(DateTime.now()),
      ),
    );
    if (punch != null) {
      await (update(punchHistory)..where((h) => h.clientPunchId.equals(punch.clientPunchId))).write(
        PunchHistoryCompanion(
          syncStatus: const Value('synced'),
          serverLogId: Value(serverLogId),
        ),
      );
    }
  }

  Future<void> markFailed(int id, String error) =>
      (update(offlinePunches)..where((p) => p.id.equals(id))).write(
        OfflinePunchesCompanion(
          syncStatus: const Value('failed'),
          retryCount: Value(
            // Increment retry count — read current value first
            // Note: handled in service layer for simplicity
            0, // placeholder; service layer reads current then increments
          ),
          errorMessage: Value(error),
        ),
      );

  Future<void> incrementRetryAndFail(int id, String error) async {
    final punch = await (select(offlinePunches)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (punch == null) return;
    final newCount = punch.retryCount + 1;
    final newStatus = newCount >= 10 ? 'failed_permanent' : 'failed';
    await (update(offlinePunches)..where((p) => p.id.equals(id))).write(
      OfflinePunchesCompanion(
        syncStatus: Value(newStatus),
        retryCount: Value(newCount),
        errorMessage: Value(error),
      ),
    );
  }

  /// Flag punches older than 24h as expired (needs admin review).
  Future<void> flagExpiredPunches() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    await (update(offlinePunches)
          ..where((p) => p.syncStatus.isIn(['pending', 'failed']))
          ..where((p) => p.createdAt.isSmallerThanValue(cutoff)))
        .write(
      const OfflinePunchesCompanion(
        syncStatus: Value('expired_pending_review'),
      ),
    );
  }

  // ── Punch History ──────────────────────────────────────────────────────────

  Future<void> upsertHistory(PunchHistoryCompanion entry) =>
      into(punchHistory).insertOnConflictUpdate(entry);

  Future<List<PunchHistoryData>> getRecentHistory({int limit = 50}) =>
      (select(punchHistory)
            ..orderBy([(h) => OrderingTerm.desc(h.createdAt)])
            ..limit(limit))
          .get();

  // ── Cached Config ──────────────────────────────────────────────────────────

  Future<CachedConfigData?> getCachedConfig() =>
      (select(cachedConfig)..orderBy([(c) => OrderingTerm.desc(c.cachedAt)])..limit(1))
          .getSingleOrNull();

  Future<void> saveCachedConfig(CachedConfigCompanion config) async {
    await delete(cachedConfig).go(); // only keep latest
    await into(cachedConfig).insert(config);
  }

  // ── Cached Punch Types ─────────────────────────────────────────────────────

  Future<List<CachedPunchType>> getCachedPunchTypes() =>
      (select(cachedPunchTypes)..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])).get();

  Future<void> savePunchTypes(List<CachedPunchTypesCompanion> types) async {
    await delete(cachedPunchTypes).go();
    await batch((b) => b.insertAll(cachedPunchTypes, types));
  }
}

// ─── Database Connection ───────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'attendance_app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
