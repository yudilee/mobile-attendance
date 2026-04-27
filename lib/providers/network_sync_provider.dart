import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import '../database/app_database.dart';
import 'punch_provider.dart';

// ─── Sync Status ──────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, allSynced, error }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final int pendingCount;
  final String? lastError;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncAt,
    this.pendingCount = 0,
    this.lastError,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    int? pendingCount,
    String? lastError,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        pendingCount: pendingCount ?? this.pendingCount,
        lastError: lastError ?? this.lastError,
      );
}

// ─── Sync Status Provider ─────────────────────────────────────────────────────

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>(
  (ref) => SyncStateNotifier(),
);

class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier() : super(const SyncState());

  void setSyncing() => state = state.copyWith(status: SyncStatus.syncing);
  void setIdle() => state = state.copyWith(status: SyncStatus.idle);
  void setAllSynced() => state = state.copyWith(
        status: SyncStatus.allSynced,
        lastSyncAt: DateTime.now(),
        pendingCount: 0,
      );
  void setError(String error) =>
      state = state.copyWith(status: SyncStatus.error, lastError: error);
  void updatePendingCount(int count) =>
      state = state.copyWith(pendingCount: count);
}

// ─── Network Sync Provider ────────────────────────────────────────────────────

final networkSyncProvider = Provider<NetworkSyncManager>((ref) {
  final api = ref.watch(apiServiceProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  final syncNotifier = ref.read(syncStateProvider.notifier);
  return NetworkSyncManager(api, offlineSync, syncNotifier);
});

// ─── Network Sync Manager ─────────────────────────────────────────────────────

class NetworkSyncManager {
  final ApiService _api;
  final OfflineSyncService _offlineSync;
  final SyncStateNotifier _syncState;
  final Logger _logger = Logger();

  bool _isSyncing = false;
  Timer? _periodicTimer;
  Timer? _connectivityDebounce;
  StreamSubscription? _connectivitySub;

  static const int _batchSize = 20; // max punches per batch request

  NetworkSyncManager(this._api, this._offlineSync, this._syncState);

  /// Start background listeners. Call once from HomeScreen.initState().
  void start() {
    _startPeriodicTimer();
    _listenToConnectivity();
    // Sync on startup in case offline punches exist
    Future.delayed(const Duration(seconds: 3), syncOfflinePunches);
  }

  /// Periodic timer: check for pending punches every 60s.
  /// This catches app-resume scenarios that connectivity events miss.
  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _logger.d('Periodic sync check...');
      syncOfflinePunches();
    });
  }

  /// Connectivity-triggered sync (debounced 5s to avoid rapid-fire).
  void _listenToConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
      if (isOnline) {
        _connectivityDebounce?.cancel();
        _connectivityDebounce = Timer(const Duration(seconds: 5), () {
          _logger.i('Network restored — triggering sync');
          syncOfflinePunches();
        });
      }
    });
  }

  /// Main sync logic: flags expired punches, then batch-syncs all pending.
  Future<void> syncOfflinePunches() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncState.setSyncing();

    try {
      // 1. Flag any punches older than 24h for admin review
      await _offlineSync.flagExpiredPunches();

      // 2. Get all pending punches
      final List<OfflinePunche> pending = await _offlineSync.getPendingPunches();
      final count = await _offlineSync.getPendingCount();
      _syncState.updatePendingCount(count);

      if (pending.isEmpty) {
        _logger.d('No pending punches to sync.');
        _syncState.setAllSynced();
        return;
      }

      _logger.i('Syncing ${pending.length} offline punches...');

      // 3. Process in batches of _batchSize
      for (var i = 0; i < pending.length; i += _batchSize) {
        final chunk = pending.skip(i).take(_batchSize).toList();
        await _syncBatch(chunk);
      }

      final remaining = await _offlineSync.getPendingCount();
      _syncState.updatePendingCount(remaining);
      if (remaining == 0) {
        _syncState.setAllSynced();
      } else {
        _syncState.setIdle();
      }
    } catch (e) {
      _logger.e('Sync sweep error: $e');
      _syncState.setError(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a batch of punches using the batch endpoint.
  Future<void> _syncBatch(List<OfflinePunche> punches) async {
    final batchPayload = punches.map((p) => <String, dynamic>{
      'employee_id': p.employeeId,
      'device_uuid': p.deviceUuid,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'is_mock_location': p.isMockLocation,
      'biometric_verified': p.biometricVerified,
      'punch_type': p.punchType,
      'timestamp': p.timestamp,
      'tz_offset_minutes': p.tzOffsetMinutes,
      'gps_time_validated': p.gpsTimeValidated,
      'client_punch_id': p.clientPunchId,
    }).toList();

    try {
      final results = await _api.submitBatch(batchPayload);

      // Process each result
      for (var i = 0; i < punches.length && i < results.length; i++) {
        final punch = punches[i];
        final result = results[i];
        final status = result['status'] as String?;

        if (status == 'success' || status == 'duplicate') {
          final logId = result['log_id'] as int? ?? 0;
          await _offlineSync.markSynced(punch.id, logId);
          _logger.i('✅ Synced punch ${punch.id} (${punch.punchType} at ${punch.timestamp})');
        } else {
          final error = result['error'] as String? ?? 'Unknown error';
          // Only keep retrying for non-permanent errors
          if (!_isPermanentError(error)) {
            await _offlineSync.markFailed(punch.id, error);
          } else {
            // Mark as permanent failure (e.g. geofence violation — won't fix itself)
            await _offlineSync.markFailed(punch.id, error);
            _logger.w('⚠️ Permanent failure for punch ${punch.id}: $error');
          }
        }
      }
    } on NetworkException {
      // Entire batch failed due to network — keep all in queue
      for (final punch in punches) {
        await _offlineSync.markFailed(punch.id, 'Network unavailable');
      }
      _logger.w('Batch sync failed due to network. Will retry.');
      rethrow; // Let caller know we hit a network error
    } catch (e) {
      // Non-network batch error
      _logger.e('Batch error: $e');
      for (final punch in punches) {
        await _offlineSync.markFailed(punch.id, e.toString());
      }
    }
  }

  /// Determine if an error should be retried or is permanent.
  bool _isPermanentError(String error) {
    final permanent = [
      'Mock location',
      'Biometric',
      'Unauthorized device',
      'Outside assigned branch',
    ];
    return permanent.any((keyword) => error.contains(keyword));
  }

  /// Exponential backoff helper (not used directly but available for future use).
  Duration backoffFor(int retryCount) {
    final seconds = min(30 * pow(2, retryCount).toInt(), 900);
    return Duration(seconds: seconds);
  }

  void dispose() {
    _periodicTimer?.cancel();
    _connectivityDebounce?.cancel();
    _connectivitySub?.cancel();
  }
}
