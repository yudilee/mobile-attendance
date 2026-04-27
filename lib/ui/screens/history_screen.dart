import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../services/offline_sync_service.dart';

// Provider to watch the local punch history
final punchHistoryProvider = StreamProvider<List<PunchHistoryData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.punchHistory).watch();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyStream = ref.watch(punchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Punch History'),
      ),
      body: historyStream.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No punch history found on this device.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Sort descending by local timestamp
          final sortedHistory = List<PunchHistoryData>.from(history)
            ..sort((a, b) => b.localTimestamp.compareTo(a.localTimestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final punch = sortedHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: punch.punchType == 'In' 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    child: Icon(
                      punch.punchType == 'In' ? Icons.login : Icons.logout,
                      color: punch.punchType == 'In' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    '${punch.punchType} Punch',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(punch.localTimestamp.toString().split('.').first),
                      if (punch.isSynced)
                        const Text('Synced ✅', style: TextStyle(color: Colors.green, fontSize: 12))
                      else
                        const Text('Pending Sync ⏳', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}
