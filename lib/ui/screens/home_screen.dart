import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/network_sync_provider.dart';
import '../widgets/connectivity_banner.dart';
import 'dashboard_screen.dart';
import 'punch_tab.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

import '../../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// Provider exposing the current tab index so other screens can switch tabs.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    Future.microtask(() => ref.read(networkSyncProvider).start());

    // Check for in-app OTA updates
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final update = await UpdateService.checkForUpdates();
      if (update.hasUpdate && mounted) {
        UpdateDialog.show(context, update);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final pendingCount = syncState.pendingCount;
    final currentIndex = ref.watch(homeTabIndexProvider);

    // Listen to external tab-switch requests (from dashboard card taps)
    ref.listen<int>(homeTabIndexProvider, (_, next) {
      // No-op here; IndexedStack handles it reactively
    });

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
      body: Column(
        children: [
          // Connectivity banner — appears automatically when offline
          const ConnectivityBanner(),
          // Tab content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(homeTabIndexProvider.notifier).state = index,
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
