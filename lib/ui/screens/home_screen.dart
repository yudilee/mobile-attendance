import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_sync_provider.dart';
import 'dashboard_screen.dart';
import 'punch_tab.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardScreen(),
    PunchTab(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start background sync manager for offline punch queue
    // Must be called at least once — safe to call multiple times (idempotent)
    Future.microtask(() => ref.read(networkSyncProvider).start());
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final pendingCount = syncState.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          // Sync status indicator in AppBar
          if (syncState.status == SyncStatus.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: '$pendingCount punch(es) pending sync. Tap to sync now.',
                child: GestureDetector(
                  onTap: () => ref.read(networkSyncProvider).syncOfflinePunches(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help & Documentation',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Punch',
          ),
          BottomNavigationBarItem(
            icon: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount', style: const TextStyle(fontSize: 9, color: Colors.white)),
                    child: const Icon(Icons.history),
                  )
                : const Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
