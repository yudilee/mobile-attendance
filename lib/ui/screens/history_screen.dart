import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/app_database.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';

final punchHistoryProvider = StreamProvider<List<PunchHistoryData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.punchHistory)
    ..orderBy([(h) => drift.OrderingTerm.desc(h.createdAt)])
    ..limit(100))
  .watch();
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Synced', 'Pending'];

  @override
  Widget build(BuildContext context) {
    final historyStream = ref.watch(punchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Punch History'),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filters[index];
                  final selected = _filter == label;
                  return FilterChip(
                    label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Theme.of(context).colorScheme.onPrimary : null)),
                    selected: selected,
                    onSelected: (bool val) {
                      setState(() => _filter = label);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    side: BorderSide.none,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          // History list with pull-to-refresh
          Expanded(
            child: historyStream.when(
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Text('No punch history on this device.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  );
                }
                final filtered = _filter == 'All'
                    ? history
                    : history.where((p) {
                        if (_filter == 'Synced') return p.syncStatus == 'synced';
                        return p.syncStatus != 'synced';
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No $_filter punches.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  );
                }

                // Group by date
                final grouped = _groupByDate(filtered);

                return RefreshIndicator(
                  onRefresh: () async {
                    // 1. Fetch server-authoritative history
                    await ref.read(networkSyncProvider).syncPunchHistory();
                    // 2. Refresh the local stream
                    ref.invalidate(punchHistoryProvider);
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: grouped.entries.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          ...entry.value.map((punch) => _PunchHistoryCard(punch: punch)),
                        ],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<PunchHistoryData>> _groupByDate(List<PunchHistoryData> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<PunchHistoryData>>{};
    for (final item in items) {
      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      String label;
      if (itemDate == today) {
        label = 'Today';
      } else if (itemDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEE, d MMM yyyy').format(item.createdAt);
      }
      grouped.putIfAbsent(label, () => []).add(item);
    }
    return grouped;
  }
}

class _PunchHistoryCard extends StatelessWidget {
  final PunchHistoryData punch;
  const _PunchHistoryCard({required this.punch});

  @override
  Widget build(BuildContext context) {
    final isIn = punch.punchType.toLowerCase().contains('in');
    final isOut = punch.punchType.toLowerCase().contains('out');

    String timeStr;
    try {
      timeStr = DateFormat('HH:mm').format(DateTime.parse(punch.timestamp).toLocal());
    } catch (_) {
      timeStr = punch.timestamp;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: isIn ? Colors.green.shade100 : isOut ? Colors.red.shade100 : Colors.blue.shade100,
          child: Icon(
            isIn ? Icons.login : isOut ? Icons.logout : Icons.schedule,
            size: 18,
            color: isIn ? Colors.green.shade700 : isOut ? Colors.red.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Text(
          '${punch.punchType} Punch',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            _SyncBadge(status: punch.syncStatus),
          ],
        ),
        trailing: punch.syncStatus == 'synced'
            ? const Icon(Icons.cloud_done, color: Colors.green, size: 18)
            : const Icon(Icons.cloud_off, color: Colors.orange, size: 18),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final String status;
  const _SyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (status == 'synced') {
      text = 'Synced'; color = Colors.green;
    } else if (status == 'expired') {
      text = 'Expired'; color = Colors.red.shade300;
    } else {
      text = 'Pending'; color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
