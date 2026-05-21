import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/app_database.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../theme.dart';

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
  String _filter = 'Today';
  static const _filters = ['Today', 'Yesterday', 'This Week', 'Older'];

  @override
  Widget build(BuildContext context) {
    final historyStream = ref.watch(punchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Work History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter capsules
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((label) {
                  final selected = _filter == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      selected: selected,
                      onSelected: (bool val) {
                        setState(() => _filter = label);
                      },
                      selectedColor: AppTheme.primaryCyan,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, borderRadius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer, color: AppTheme.primaryCyan, size: 24),
                        const SizedBox(height: 12),
                        const Text('Total Work Hours', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('8h 45m', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(context: context, borderRadius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 24),
                        const SizedBox(height: 12),
                        const Text('Status', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text('Clocked In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // History list with pull-to-refresh
          Expanded(
            child: historyStream.when(
              data: (history) {
                if (history.isEmpty) {
                  return Center(
                    child: Text('No punch history on this device.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  );
                }
                
                // Filter logic
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));
                final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
                
                final filtered = history.where((p) {
                  final itemDate = DateTime(p.createdAt.year, p.createdAt.month, p.createdAt.day);
                  if (_filter == 'Today') return itemDate == today;
                  if (_filter == 'Yesterday') return itemDate == yesterday;
                  if (_filter == 'This Week') return itemDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
                  return itemDate.isBefore(startOfWeek);
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: grouped.entries.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 12),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan)),
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
        label = 'TODAY, ${DateFormat('MMM d').format(item.createdAt).toUpperCase()}';
      } else if (itemDate == yesterday) {
        label = 'YESTERDAY, ${DateFormat('MMM d').format(item.createdAt).toUpperCase()}';
      } else {
        label = DateFormat('EEE, MMM d').format(item.createdAt).toUpperCase();
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

    String timeStr;
    try {
      timeStr = DateFormat('hh:mm a').format(DateTime.parse(punch.timestamp).toLocal());
    } catch (_) {
      timeStr = punch.timestamp;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(context: context, borderRadius: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isIn ? AppTheme.primaryCyan.withOpacity(0.15) : AppTheme.secondaryViolet.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIn ? Icons.arrow_downward : Icons.arrow_upward,
            size: 20,
            color: isIn ? AppTheme.primaryCyan : AppTheme.secondaryViolet,
          ),
        ),
        title: Text(
          isIn ? 'Clocked In' : 'Clocked Out',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          timeStr, 
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)
        ),
        trailing: _SyncBadge(status: punch.syncStatus),
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
      text = 'SYNCED'; color = AppTheme.successGreen;
    } else if (status == 'expired') {
      text = 'EXPIRED'; color = AppTheme.errorRed;
    } else {
      text = 'PENDING'; color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}
