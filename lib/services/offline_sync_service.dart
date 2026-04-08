import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class OfflineSyncService {
  static const String _queueKey = 'offline_punches';
  final Logger _logger = Logger();

  /// Saves a single punch to the local offline queue
  Future<void> saveOfflinePunch(Map<String, dynamic> punchData) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offlineQueue = prefs.getStringList(_queueKey) ?? [];
    
    // Convert punchData to JSON string
    offlineQueue.add(jsonEncode(punchData));
    
    await prefs.setStringList(_queueKey, offlineQueue);
    _logger.i('Saved punch to offline queue. Total in queue: ${offlineQueue.length}');
  }

  /// Retrieves the current queue of offline punches
  Future<List<Map<String, dynamic>>> getOfflinePunches() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> offlineStrings = prefs.getStringList(_queueKey) ?? [];
    
    final List<Map<String, dynamic>> queue = [];
    for (String punchStr in offlineStrings) {
      try {
        queue.add(jsonDecode(punchStr) as Map<String, dynamic>);
      } catch (e) {
        _logger.e('Failed to decode offline punch: $punchStr', error: e);
      }
    }
    return queue;
  }

  /// Restores a queue that couldn't be synced (partly or fully)
  Future<void> restoreQueue(List<Map<String, dynamic>> remainingQueue) async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> offlineQueue = remainingQueue.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_queueKey, offlineQueue);
    _logger.i('Queue restored. Total in queue: ${offlineQueue.length}');
  }

  /// Clears the entire offline queue
  Future<void> clearOfflinePunches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    _logger.i('Offline queue cleared.');
  }
}
