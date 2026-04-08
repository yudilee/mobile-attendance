import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';
import 'punch_provider.dart';

final networkSyncProvider = Provider<NetworkSyncManager>((ref) {
  final api = ref.watch(apiServiceProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return NetworkSyncManager(api, offlineSync);
});

class NetworkSyncManager {
  final ApiService _api;
  final OfflineSyncService _offlineSync;
  final Logger _logger = Logger();
  bool _isSyncing = false;

  NetworkSyncManager(this._api, this._offlineSync);

  /// Subscribes to network changes and triggers sync when online
  void listenToNetworkChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile || 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.ethernet) {
        _logger.i('Network restored, attempting offline sync...');
        syncOfflinePunches();
      }
    });
  }

  /// Manually synchronizes pending offline punches
  Future<void> syncOfflinePunches() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await _offlineSync.getOfflinePunches();
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      _logger.i('Found ${queue.length} punches to sync.');
      
      final List<Map<String, dynamic>> failedQueue = [];

      for (final punchData in queue) {
        try {
          await _api.submitPunch(
            employeeId: punchData['employee_id'],
            deviceUuid: punchData['device_uuid'],
            lat: punchData['latitude'],
            lon: punchData['longitude'],
            isMocked: punchData['is_mock_location'],
            biometricVerified: punchData['biometric_verified'],
            punchType: punchData['punch_type'],
            timestamp: punchData['timestamp'],
            tzOffsetMinutes: punchData['tz_offset_minutes'] ?? 420,
            gpsValidated: punchData['gps_time_validated'] ?? false,
          );
          _logger.i('Successfully synced offline punch: ${punchData['punch_type']} at ${punchData['timestamp']}');
        } on NetworkException {
          // Keep it in the queue for the next retry
          failedQueue.add(punchData);
          _logger.w('Network failed during sync, keeping in queue.');
        } catch (e) {
             // For other errors (like Server 400), don't keep retrying as it will always fail
             _logger.e('Failed to sync offline punch (discarding): $e');
        }
      }

      // Restore any punches that failed due to network issues
      if (failedQueue.isNotEmpty) {
        await _offlineSync.restoreQueue(failedQueue);
      } else {
        await _offlineSync.clearOfflinePunches();
      }

    } finally {
      _isSyncing = false;
    }
  }
}
