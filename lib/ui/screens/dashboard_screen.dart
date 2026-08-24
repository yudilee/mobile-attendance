import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../services/attendance_calculator.dart';
import '../../providers/punch_provider.dart';
import '../../providers/network_sync_provider.dart';
import '../../services/security_service.dart';
import '../../services/app_settings.dart';
import '../theme.dart';
import 'history_screen.dart';
import 'help_screen.dart';
import 'home_screen.dart'; // for homeTabIndexProvider
import 'field_operations_screen.dart';
import 'leave_permit_hub_screen.dart';


final userProfileProvider = FutureProvider<String>((ref) async {
  // We can force this provider to refresh when config changes
  // by depending on deviceConfigProvider if needed, but since it's cached, 
  // we'll just read from AppSettings
  final name = await AppSettings.getEmployeeName();
  final id = await AppSettings.getEmployeeId();
  if (name.isNotEmpty) return name;
  if (id.isNotEmpty) return id;
  return 'Employee';
});

// ─── Security Status Provider ─────────────────────────────────────────────
// Checks device security state and returns a human-readable status.
final securityStatusProvider = FutureProvider<String>((ref) async {
  final security = SecurityService();
  final isCompromised = await security.isDeviceCompromised();
  if (isCompromised) {
    return 'rooted';
  }
  // If we reach here, it means no root access found.
  // Unlocked bootloader is NOT treated as compromised.
  return 'secure';
});


class DashboardScreen extends ConsumerStatefulWidget {

  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _employeeId = 'Employee';

  @override
  void initState() {
    super.initState();
    _loadEmployeeProfile();
  }

  Future<void> _loadEmployeeProfile() async {
    final id = await AppSettings.getEmployeeId();
    final name = await AppSettings.getEmployeeName();
    if (id.isNotEmpty) {
      setState(() {
        _employeeId = name.isNotEmpty ? name : id;
      });
    }
  }

  /// Pull-to-refresh: sync punch history from backend then refresh local stats.
  Future<void> _refreshDashboard() async {
    await ref.read(networkSyncProvider).syncPunchHistory();
    ref.invalidate(punchHistoryProvider);
  }

  /// Returns a time-appropriate greeting.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️ Good Morning';
    if (hour >= 12 && hour < 17) return '🌤 Good Afternoon';
    if (hour >= 17 && hour < 21) return '🌆 Good Evening';
    return '🌙 Working Late?';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final syncState = ref.watch(syncStateProvider);
    final pendingCount = syncState.pendingCount;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    // Watch punch history so dashboard rebuilds when punches are added/synced
    ref.watch(punchHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryCyan,
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            // Always scrollable so pull-to-refresh works even when content is short
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  '${_getGreeting()}, $_employeeId',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pull down to sync latest data',
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Sync status card (visible when there are pending punches)
                if (pendingCount > 0 || syncState.status == SyncStatus.syncing || syncState.status == SyncStatus.error)
                  _SyncStatusCard(
                    syncState: syncState,
                    onSyncTap: () => ref.read(networkSyncProvider).syncOfflinePunches(),
                  ),
                if (pendingCount > 0 || syncState.status == SyncStatus.syncing || syncState.status == SyncStatus.error)
                  const SizedBox(height: 24),

                // Today's summary card (Shift Status) — tappable → History
                InkWell(
                  onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
                  borderRadius: BorderRadius.circular(20),
                  child: _TodaySummaryCard(db: db),
                ),
                const SizedBox(height: 20),

                // Field Operations Card (Mechanic Storing & Sales Canvassing)
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FieldOperationsScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900.withOpacity(0.8), Colors.indigo.shade800.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.location_on_outlined, color: Colors.cyanAccent, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Field Operations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'GPS',
                                    style: TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mechanic Storing • Sales Canvassing Visits',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Leave & Permits Hub Card (Annual / Sick Leave & Late Arrival Permits)
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeavePermitHubScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF064E3B).withOpacity(0.85), const Color(0xFF0F172A).withOpacity(0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.event_available_outlined, color: Color(0xFF34D399), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Leave & Permits',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'HUB',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Apply Cuti • Late Arrival & Permission Permits',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Weekly stats — tappable → History
                InkWell(
                  onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
                  borderRadius: BorderRadius.circular(20),
                  child: _WeeklyOverviewCard(db: db),
                ),
                const SizedBox(height: 20),

                // Monthly stats — tappable → History
                InkWell(
                  onTap: () => ref.read(homeTabIndexProvider.notifier).state = 2,
                  borderRadius: BorderRadius.circular(20),
                  child: _MonthlyStatsCard(db: db),
                ),
                const SizedBox(height: 24),

                // Security status indicator
                _SecurityStatusCard(),

                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '\u00A9 ${DateTime.now().year} IT Dept HRM Group',
                    style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sync Status Card ──────────────────────────────────────────────────────

class _SyncStatusCard extends StatelessWidget {
  final SyncState syncState;
  final VoidCallback onSyncTap;

  const _SyncStatusCard({
    required this.syncState,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    late final Color borderColor;
    late final IconData icon;
    final String title;
    final String subtitle;

    switch (syncState.status) {
      case SyncStatus.syncing:
        borderColor = AppTheme.primaryCyan;
        icon = Icons.sync;
        title = 'Syncing...';
        subtitle = '${syncState.pendingCount} punch(es) remaining';
      case SyncStatus.allSynced:
        borderColor = AppTheme.successGreen;
        icon = Icons.cloud_done;
        title = 'All Synced';
        subtitle = syncState.lastSyncAt != null
            ? 'Last sync: ${_formatTime(syncState.lastSyncAt!)}'
            : 'No pending punches';
      case SyncStatus.error:
        borderColor = AppTheme.errorRed;
        icon = Icons.cloud_off;
        title = 'Sync Error';
        subtitle = syncState.lastError ?? 'Unknown error';
      default:
        borderColor = Colors.orange;
        icon = Icons.cloud_upload;
        title = '${syncState.pendingCount} Punch(es) Pending';
        subtitle = 'Tap to sync now';
    }

    return GestureDetector(
      onTap: syncState.status == SyncStatus.syncing ? null : onSyncTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassDecoration(context: context, borderRadius: 16).copyWith(
          color: borderColor.withOpacity(0.08),
          border: Border.all(color: borderColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: borderColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: borderColor, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: borderColor.withOpacity(0.8))),
                ],
              ),
            ),
            if (syncState.status == SyncStatus.syncing)
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: borderColor),
              )
            else
              IconButton(
                onPressed: onSyncTap,
                icon: const Icon(Icons.refresh, size: 20),
                color: borderColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ─── Today's Summary Card ────────────────────────────────────────────────────

class _TodaySummaryCard extends ConsumerWidget {
  final AppDatabase db;

  const _TodaySummaryCard({required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AttendanceSummary>(
      future: AttendanceCalculator.calculateTodaySummary(
        db,
        now: DateTime.now(),
      ),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          decoration: AppTheme.glassDecoration(context: context),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
              else if (summary != null)
                Builder(builder: (context) {
                  final textColor = Theme.of(context).colorScheme.onSurface;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildShiftItem(
                              icon: Icons.login,
                              label: 'Check In',
                              value: summary.clockInTime != null
                                  ? _formatTime(DateTime.parse(summary.clockInTime!))
                                  : '--:--',
                              color: AppTheme.primaryCyan,
                              textColor: textColor,
                            ),
                          ),
                          Expanded(
                            child: _buildShiftItem(
                              icon: Icons.logout,
                              label: 'Check Out',
                              value: summary.clockOutTime != null
                                  ? _formatTime(DateTime.parse(summary.clockOutTime!))
                                  : '--:--',
                              color: AppTheme.secondaryViolet,
                              textColor: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildShiftItem(
                              icon: Icons.access_time,
                              label: 'Work Duration',
                              value: summary.todayWorkDuration != null
                                  ? _formatDuration(summary.todayWorkDuration!)
                                  : '--h --m',
                              color: Colors.grey.shade400,
                              textColor: textColor,
                            ),
                          ),
                          Expanded(
                            child: _buildShiftItem(
                              icon: Icons.trending_up,
                              label: 'Overtime',
                              value: (summary.todayWorkDuration != null && summary.todayWorkDuration!.inHours > 8)
                                  ? _formatDuration(summary.todayWorkDuration! - const Duration(hours: 8))
                                  : '0h 0m',
                              color: Colors.grey.shade400,
                              textColor: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                })
              else if (snapshot.hasError)
                Center(child: Text('Error loading data', style: TextStyle(color: AppTheme.errorRed))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftItem({required IconData icon, required String label, required String value, required Color color, required Color textColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ],
    );
  }


  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}

// ─── Weekly Overview Card ────────────────────────────────────────────────────

class _WeeklyOverviewCard extends ConsumerWidget {
  final AppDatabase db;

  const _WeeklyOverviewCard({required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AttendanceSummary>(
      future: AttendanceCalculator.calculateWeeklySummary(
        db,
        now: DateTime.now(),
      ),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          decoration: AppTheme.glassDecoration(context: context),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(Icons.more_horiz, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
              else if (summary != null)
                Column(
                  children: [
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MiniStat(
                          label: 'Present',
                          value: '${summary.totalPresent}',
                          color: AppTheme.primaryCyan,
                        ),
                        _MiniStat(
                          label: 'Late',
                          value: '${summary.totalLate}',
                          color: Colors.orangeAccent,
                        ),
                        _MiniStat(
                          label: 'Total Hrs',
                          value: summary.totalWorkHours.toStringAsFixed(1),
                          color: AppTheme.secondaryViolet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Weekly day indicators
                    _WeeklyDayIndicators(summary: summary),
                  ],
                )
              else if (snapshot.hasError)
                Center(child: Text('Error loading weekly data', style: TextStyle(color: AppTheme.errorRed))),
            ],
          ),
        );
      },
    );
  }
}

// ─── Weekly Day Indicators ───────────────────────────────────────────────────

class _WeeklyDayIndicators extends StatelessWidget {
  final AttendanceSummary summary;

  const _WeeklyDayIndicators({required this.summary});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Find Monday of current week
    final daysFromMonday = now.weekday - DateTime.monday;
    final monday =
        DateTime(now.year, now.month, now.day - daysFromMonday);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        // Monday to Friday
        final day = monday.add(Duration(days: index));
        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;
        // Determine color (simplified — in production, check actual daily data)
        final hasData = index < summary.totalPresent;
        final isLate = index < summary.totalLate;

        Color indicatorColor;
        Color bgColor;
        if (isToday) {
          indicatorColor = Theme.of(context).colorScheme.onSurface;
          bgColor = AppTheme.primaryCyan;
        } else if (isLate) {
          indicatorColor = Colors.orangeAccent;
          bgColor = Colors.orangeAccent.withOpacity(0.15);
        } else if (hasData) {
          indicatorColor = AppTheme.successGreen;
          bgColor = AppTheme.successGreen.withOpacity(0.15);
        } else {
          indicatorColor = Colors.grey.shade500;
          bgColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.05);
        }

        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: isToday ? [
                  BoxShadow(color: AppTheme.primaryCyan.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)
                ] : null,
              ),
              child: Center(
                child: Text(
                  ['M', 'T', 'W', 'T', 'F'][index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: indicatorColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                color: isToday
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey.shade400,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Monthly Stats Card ──────────────────────────────────────────────────────

class _MonthlyStatsCard extends ConsumerWidget {
  final AppDatabase db;

  const _MonthlyStatsCard({required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AttendanceSummary>(
      future: AttendanceCalculator.calculateMonthlySummary(
        db,
        now: DateTime.now(),
      ),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          decoration: AppTheme.glassDecoration(context: context),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(Icons.calendar_month, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primaryCyan))
              else if (summary != null)
                Column(
                  children: [
                    // Stats in a 3-column grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Present',
                            value: '${summary.totalPresent}',
                            color: AppTheme.primaryCyan,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Late',
                            value: '${summary.totalLate}',
                            color: Colors.orangeAccent,
                            icon: Icons.warning_amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Absent',
                            value: '${summary.totalAbsent}',
                            color: AppTheme.errorRed,
                            icon: Icons.cancel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Percentage breakdown
                    _PercentageBar(summary: summary),
                  ],
                )
              else if (snapshot.hasError)
                Center(child: Text('Error loading monthly data', style: TextStyle(color: AppTheme.errorRed))),
            ],
          ),
        );
      },
    );
  }
}

// ─── Percentage Bar ──────────────────────────────────────────────────────────

class _PercentageBar extends StatelessWidget {
  final AttendanceSummary summary;

  const _PercentageBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalPresent +
        summary.totalLate +
        summary.totalAbsent;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final presentPct = summary.totalPresent / total;
    final latePct = summary.totalLate / total;
    final absentPct = summary.totalAbsent / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attendance Goal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(presentPct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (presentPct > 0)
                  Expanded(
                    flex: (presentPct * 100).round(),
                    child: Container(color: AppTheme.primaryCyan),
                  ),
                if (latePct > 0)
                  Expanded(
                    flex: (latePct * 100).round(),
                    child: Container(color: Colors.orangeAccent),
                  ),
                if (absentPct > 0)
                  Expanded(
                    flex: (absentPct * 100).round(),
                    child: Container(color: AppTheme.errorRed),
                  ),
                if (total == 0) // Fallback if no punches yet
                  Expanded(child: Container(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Security Status Card ─────────────────────────────────────────────────
// Shows device security status on the dashboard.
// - 🟢 "Secure" — No root access detected (most devices)
// - 🔴 "Device Compromised" — Root access detected (su binary found)
// Unlocked bootloader is NOT treated as compromised.
class _SecurityStatusCard extends ConsumerWidget {
  const _SecurityStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(securityStatusProvider).when(
      data: (status) {
        final bool isSecure = status == 'secure';
        final IconData icon = isSecure ? Icons.security : Icons.gpp_bad;
        final String title = isSecure ? 'Device Secure' : 'Device Compromised';
        final String subtitle = isSecure
            ? 'No root access detected'
            : 'Root access detected — contact IT admin';

        return GestureDetector(
          onTap: () {
            // Navigate to help screen for more info
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppTheme.glassDecoration(context: context).copyWith(
              color: isSecure ? AppTheme.successGreen.withOpacity(0.05) : AppTheme.errorRed.withOpacity(0.05),
              border: Border.all(color: isSecure ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.errorRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSecure ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.errorRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSecure ? AppTheme.successGreen : AppTheme.errorRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSecure ? AppTheme.successGreen : AppTheme.errorRed,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.help_outline,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
