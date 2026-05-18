import '../database/app_database.dart';

class AttendanceSummary {
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final double totalWorkHours;
  final double averageWorkHours;
  final double overtimeHours;
  final DateTime? firstPunchToday;
  final DateTime? lastPunchToday;
  final String? clockInTime;
  final String? clockOutTime;
  final Duration? todayWorkDuration;
  final bool isPresentToday;
  final bool isLateToday;

  AttendanceSummary({
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalWorkHours,
    required this.averageWorkHours,
    required this.overtimeHours,
    this.firstPunchToday,
    this.lastPunchToday,
    this.clockInTime,
    this.clockOutTime,
    this.todayWorkDuration,
    this.isPresentToday = false,
    this.isLateToday = false,
  });
}

class AttendanceCalculator {
  /// Calculate today's attendance summary
  static Future<AttendanceSummary> calculateTodaySummary(
    AppDatabase historyDao, {
    DateTime? now,
  }) async {
    now ??= DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(hours: 24));

    final todayPunches =
        await historyDao.getPunchesInRange(todayStart, todayEnd);

    // Find clock-in (first punch) and clock out (last punch) for today
    DateTime? clockIn, clockOut;
    for (final punch in todayPunches) {
      final t = DateTime.parse(punch.timestamp);
      final pType = punch.punchType.toLowerCase();
      // Assuming punch_type 'in' or 'out' - adjust based on your punch type codes
      if (pType.contains('in') || pType.contains('1')) {
        if (clockIn == null || t.isBefore(clockIn)) clockIn = t;
      } else if (pType.contains('out') || pType.contains('2')) {
        if (clockOut == null || t.isAfter(clockOut)) clockOut = t;
      }
    }

    // Calculate today's work duration
    Duration? todayDuration;
    if (clockIn != null && clockOut != null) {
      todayDuration = clockOut.difference(clockIn);
    } else if (clockIn != null) {
      todayDuration = now.difference(clockIn);
    }

    // Determine if late (after 9 AM configurable)
    final isLate = clockIn != null && clockIn.hour >= 9;

    return AttendanceSummary(
      isPresentToday: clockIn != null,
      isLateToday: isLate,
      clockInTime: clockIn?.toIso8601String(),
      clockOutTime: clockOut?.toIso8601String(),
      todayWorkDuration: todayDuration,
      totalPresent: 0, // Will be computed in monthly summary
      totalLate: 0,
      totalAbsent: 0,
      totalWorkHours: 0,
      averageWorkHours: 0,
      overtimeHours: 0,
    );
  }

  /// Calculate monthly summary
  static Future<AttendanceSummary> calculateMonthlySummary(
    AppDatabase historyDao, {
    DateTime? now,
    int? month,
    int? year,
  }) async {
    now ??= DateTime.now();
    month ??= now.month;
    year ??= now.year;

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final monthPunches =
        await historyDao.getPunchesInRange(monthStart, monthEnd);

    // Group by date and compute stats
    final dailyStats = <String, List>{};
    for (final punch in monthPunches) {
      final t = DateTime.parse(punch.timestamp);
      final dateKey =
          '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      dailyStats.putIfAbsent(dateKey, () => []).add(punch);
    }

    int present = 0, late = 0;
    double totalHours = 0;

    for (final date in dailyStats.keys) {
      final punches = dailyStats[date]!;
      // Find first clock-in
      final firstIn = punches.cast<dynamic>().where((p) =>
          p.punchType.contains('in') || p.punchType.contains('1'));
      if (firstIn.isNotEmpty) {
        present++;
        final firstTime = DateTime.parse(firstIn.first.timestamp);
        if (firstTime.hour >= 9) late++;
      }

      // Calculate total hours for this day
      DateTime? dayIn, dayOut;
      for (final p in punches) {
        final pt = DateTime.parse(p.timestamp);
        final pType = p.punchType.toLowerCase();
        if (pType.contains('in') || pType.contains('1')) {
          if (dayIn == null || pt.isBefore(dayIn)) dayIn = pt;
        } else if (pType.contains('out') || pType.contains('2')) {
          if (dayOut == null || pt.isAfter(dayOut)) dayOut = pt;
        }
      }
      if (dayIn != null && dayOut != null) {
        totalHours += dayOut.difference(dayIn).inMinutes / 60.0;
      }
    }

    // Approximate absent days (weekdays - present days in range)
    int workingDays = 0;
    for (var d = monthStart;
        d.isBefore(monthEnd);
        d = d.add(const Duration(days: 1))) {
      if (d.weekday != DateTime.sunday &&
          d.weekday != DateTime.saturday) {
        workingDays++;
      }
    }

    return AttendanceSummary(
      isPresentToday: false,
      isLateToday: false,
      totalPresent: present,
      totalLate: late,
      totalAbsent: workingDays - present,
      totalWorkHours: totalHours,
      averageWorkHours: present > 0 ? totalHours / present : 0,
      overtimeHours: 0,
    );
  }

  /// Calculate weekly summary
  static Future<AttendanceSummary> calculateWeeklySummary(
    AppDatabase historyDao, {
    DateTime? now,
  }) async {
    now ??= DateTime.now();
    // Find the start of the current week (Monday)
    final daysFromMonday = now.weekday - DateTime.monday;
    final weekStart =
        DateTime(now.year, now.month, now.day - daysFromMonday);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekPunches =
        await historyDao.getPunchesInRange(weekStart, weekEnd);

    // Group by date
    final dailyStats = <String, List>{};
    for (final punch in weekPunches) {
      final t = DateTime.parse(punch.timestamp);
      final dateKey =
          '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      dailyStats.putIfAbsent(dateKey, () => []).add(punch);
    }

    int present = 0, late = 0;
    double totalHours = 0;

    for (final date in dailyStats.keys) {
      final punches = dailyStats[date]!;
      DateTime? dayIn, dayOut;
      for (final p in punches) {
        final pt = DateTime.parse(p.timestamp);
        final pType = p.punchType.toLowerCase();
        if (pType.contains('in') || pType.contains('1')) {
          if (dayIn == null || pt.isBefore(dayIn)) dayIn = pt;
          if (pt.hour >= 9) late++;
        } else if (pType.contains('out') || pType.contains('2')) {
          if (dayOut == null || pt.isAfter(dayOut)) dayOut = pt;
        }
      }
      if (dayIn != null) present++;
      if (dayIn != null && dayOut != null) {
        totalHours += dayOut.difference(dayIn).inMinutes / 60.0;
      }
    }

    return AttendanceSummary(
      isPresentToday: false,
      isLateToday: false,
      totalPresent: present,
      totalLate: late,
      totalAbsent: 0,
      totalWorkHours: totalHours,
      averageWorkHours: present > 0 ? totalHours / present : 0,
      overtimeHours: 0,
    );
  }
}
