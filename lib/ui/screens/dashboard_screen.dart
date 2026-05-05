import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../services/attendance_calculator.dart';
import '../../providers/punch_provider.dart';
import '../theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's summary card
            _TodaySummaryCard(db: db),
            const SizedBox(height: 16),
            // Weekly stats
            _WeeklyOverviewCard(db: db),
            const SizedBox(height: 16),
            // Monthly calendar/mini stats
            _MonthlyStatsCard(db: db),
          ],
        ),
      ),
    );
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

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.today,
                        color: AppTheme.primaryTeal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    if (!isLoading && summary != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: summary.isPresentToday
                              ? (summary.isLateToday
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          !summary.isPresentToday
                              ? 'Absent'
                              : summary.isLateToday
                                  ? 'Late'
                                  : 'Present',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: !summary.isPresentToday
                                ? Colors.grey
                                : summary.isLateToday
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryTeal),
                    ),
                  )
                else if (summary != null) ...[
                  // Date
                  Text(
                    _formatDate(DateTime.now()),
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Work duration
                  if (summary.todayWorkDuration != null) ...[
                    _StatRow(
                      icon: Icons.access_time,
                      label: 'Work Duration',
                      value: _formatDuration(summary.todayWorkDuration!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // First punch
                  if (summary.clockInTime != null)
                    _StatRow(
                      icon: Icons.login,
                      label: 'Clock In',
                      value: _formatTime(DateTime.parse(summary.clockInTime!)),
                    ),
                  if (summary.clockOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _StatRow(
                        icon: Icons.logout,
                        label: 'Clock Out',
                        value:
                            _formatTime(DateTime.parse(summary.clockOutTime!)),
                      ),
                    ),
                  // Overtime indicator
                  if (summary.todayWorkDuration != null &&
                      summary.todayWorkDuration!.inHours > 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Overtime: ${_formatDuration(summary.todayWorkDuration! - const Duration(hours: 8))}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!summary.isPresentToday)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'No punch recorded today',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ] else if (snapshot.hasError)
                  Center(
                    child: Text(
                      'Error loading data',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
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

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.date_range,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'This Week',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryTeal),
                    ),
                  )
                else if (summary != null) ...[
                  // Stats row
                  Row(
                    children: [
                      _MiniStat(
                        label: 'Present',
                        value: '${summary.totalPresent}',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _MiniStat(
                        label: 'Late',
                        value: '${summary.totalLate}',
                        color: Colors.orange,
                      ),
                      const Spacer(),
                      _MiniStat(
                        label: 'Total Hours',
                        value: summary.totalWorkHours.toStringAsFixed(1),
                        color: AppTheme.primaryTeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Weekly day indicators
                  _WeeklyDayIndicators(summary: summary),
                ] else if (snapshot.hasError)
                  Center(
                    child: Text(
                      'Error loading weekly data',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
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
        if (isToday) {
          indicatorColor = AppTheme.primaryTeal;
        } else if (isLate) {
          indicatorColor = Colors.orange;
        } else if (hasData) {
          indicatorColor = Colors.green;
        } else {
          indicatorColor = Colors.red.shade200;
        }

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: indicatorColor.withOpacity(isToday ? 0.2 : 0.15),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: indicatorColor, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: indicatorColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][index],
              style: TextStyle(
                fontSize: 10,
                color: isToday
                    ? AppTheme.primaryTeal
                    : AppTheme.textMuted,
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

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Month to Date',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const Spacer(),
                    if (!isLoading && summary != null)
                      Text(
                        _monthName(DateTime.now().month),
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryTeal),
                    ),
                  )
                else if (summary != null) ...[
                  // Stats in a 3-column grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Present',
                          value: '${summary.totalPresent}',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: 'Late',
                          value: '${summary.totalLate}',
                          color: Colors.orange,
                          icon: Icons.warning_amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: 'Absent',
                          value: '${summary.totalAbsent}',
                          color: Colors.red,
                          icon: Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Percentage breakdown
                  _PercentageBar(summary: summary),
                  const SizedBox(height: 12),
                  // Average hours
                  Row(
                    children: [
                      const Icon(Icons.query_stats,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Avg. ${summary.averageWorkHours.toStringAsFixed(1)} hrs/day',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${summary.totalWorkHours.toStringAsFixed(1)} total hrs',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ] else if (snapshot.hasError)
                  Center(
                    child: Text(
                      'Error loading monthly data',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
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
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (presentPct > 0)
                  Expanded(
                    flex: (presentPct * 100).round(),
                    child: Container(color: Colors.green),
                  ),
                if (latePct > 0)
                  Expanded(
                    flex: (latePct * 100).round(),
                    child: Container(color: Colors.orange),
                  ),
                if (absentPct > 0)
                  Expanded(
                    flex: (absentPct * 100).round(),
                    child: Container(color: Colors.red.shade300),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendItem(
              color: Colors.green,
              label:
                  '${(presentPct * 100).toStringAsFixed(0)}% Present',
            ),
            const SizedBox(width: 12),
            _LegendItem(
              color: Colors.orange,
              label: '${(latePct * 100).toStringAsFixed(0)}% Late',
            ),
            const SizedBox(width: 12),
            _LegendItem(
              color: Colors.red.shade300,
              label: '${(absentPct * 100).toStringAsFixed(0)}% Absent',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
