import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_session.dart';
import '../services/database_service.dart';

class StatisticsController extends GetxController {
  static StatisticsController get instance => Get.find();

  // Reactive variables
  final _isLoading = false.obs;
  final _todaySessions = <NotificationSession>[].obs;
  final _weeklySessions = <NotificationSession>[].obs;
  final _monthlySessions = <NotificationSession>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  List<NotificationSession> get todaySessions => _todaySessions;
  List<NotificationSession> get weeklySessions => _weeklySessions;
  List<NotificationSession> get monthlySessions => _monthlySessions;

  // Today statistics
  int get todayTotalSessions => _todaySessions.length;
  int get todayCompletedSessions => _todaySessions
      .where((s) => s.status == SessionStatusHive.completed)
      .length;
  int get todaySkippedSessions =>
      _todaySessions.where((s) => s.status == SessionStatusHive.skipped).length;
  int get todaySnoozedSessions =>
      _todaySessions.where((s) => s.status == SessionStatusHive.snoozed).length;
  double get todayCompletionRate => todayTotalSessions > 0
      ? todayCompletedSessions / todayTotalSessions
      : 0.0;

  // Weekly statistics
  int get weeklyTotalSessions => _weeklySessions.length;
  int get weeklyCompletedSessions => _weeklySessions
      .where((s) => s.status == SessionStatusHive.completed)
      .length;
  int get weeklySkippedSessions => _weeklySessions
      .where((s) => s.status == SessionStatusHive.skipped)
      .length;
  int get weeklySnoozedSessions => _weeklySessions
      .where((s) => s.status == SessionStatusHive.snoozed)
      .length;
  double get weeklyCompletionRate => weeklyTotalSessions > 0
      ? weeklyCompletedSessions / weeklyTotalSessions
      : 0.0;

  // Monthly statistics
  int get monthlyTotalSessions => _monthlySessions.length;
  int get monthlyCompletedSessions => _monthlySessions
      .where((s) => s.status == SessionStatusHive.completed)
      .length;
  int get monthlySkippedSessions => _monthlySessions
      .where((s) => s.status == SessionStatusHive.skipped)
      .length;
  int get monthlySnoozedSessions => _monthlySessions
      .where((s) => s.status == SessionStatusHive.snoozed)
      .length;
  double get monthlyCompletionRate => monthlyTotalSessions > 0
      ? monthlyCompletedSessions / monthlyTotalSessions
      : 0.0;

  // Advanced statistics
  int get activeDaysThisMonth {
    final uniqueDays = <String>{};
    for (final session in _monthlySessions) {
      final dateKey =
          '${session.scheduledTime.year}-${session.scheduledTime.month}-${session.scheduledTime.day}';
      uniqueDays.add(dateKey);
    }
    return uniqueDays.length;
  }

  double get averageSessionsPerDay {
    if (activeDaysThisMonth == 0) return 0.0;
    return monthlyTotalSessions / activeDaysThisMonth;
  }

  // Daily stats for the week (for chart)
  Map<String, int> get dailyStatsForWeek {
    final stats = <String, int>{};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final daySessionsCount = _weeklySessions.where((session) {
        final sessionDay = session.scheduledTime;
        return sessionDay.year == day.year &&
            sessionDay.month == day.month &&
            sessionDay.day == day.day;
      }).length;

      stats[dayKey] = daySessionsCount;
    }

    return stats;
  }

  // Weekly trends for the month
  Map<int, int> get weeklyTrends {
    final trends = <int, int>{};
    final now = DateTime.now();

    for (int week = 1; week <= 4; week++) {
      final weekStart = now.subtract(Duration(days: (5 - week) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekSessions = _monthlySessions.where((session) {
        return session.scheduledTime
                .isAfter(weekStart.subtract(const Duration(days: 1))) &&
            session.scheduledTime
                .isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;

      trends[week] = weekSessions;
    }

    return trends;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('📊 StatisticsController initialized');
    _initialize();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    try {
      _isLoading.value = true;
      await _loadAllStatistics();
    } catch (e) {
      debugPrint('❌ Error initializing StatisticsController: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load all statistics
  Future<void> _loadAllStatistics() async {
    try {
      // Load today's sessions
      final todayStats = await DatabaseService.instance.getStatistics(days: 1);
      _todaySessions.assignAll(todayStats['sessions'] ?? []);

      // Load weekly sessions
      final weeklyStats = await DatabaseService.instance.getStatistics(days: 7);
      _weeklySessions.assignAll(weeklyStats['sessions'] ?? []);

      // Load monthly sessions
      final monthlyStats =
          await DatabaseService.instance.getStatistics(days: 30);
      _monthlySessions.assignAll(monthlyStats['sessions'] ?? []);

      debugPrint(
          '📊 Statistics loaded: Today: ${todayTotalSessions}, Weekly: ${weeklyTotalSessions}, Monthly: ${monthlyTotalSessions}');
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      debugPrint('🔄 Refreshing statistics...');
      _isLoading.value = true;
      await _loadAllStatistics();
      debugPrint('✅ Statistics refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing statistics: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถรีเฟรชข้อมูลได้');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get insights for a specific period
  List<String> getInsights(String period) {
    final insights = <String>[];

    switch (period) {
      case 'วันนี้':
        _generateTodayInsights(insights);
        break;
      case 'สัปดาห์นี้':
        _generateWeeklyInsights(insights);
        break;
      case 'เดือนนี้':
        _generateMonthlyInsights(insights);
        break;
    }

    return insights;
  }

  void _generateTodayInsights(List<String> insights) {
    if (todayTotalSessions == 0) {
      insights.add('วันนี้ยังไม่มีกิจกรรมออกกำลังกาย ลองเปิดการแจ้งเตือนดูนะ');
      return;
    }

    if (todayCompletionRate >= 0.8) {
      insights.add('วันนี้ทำได้ดีมาก! คงสภาพแบบนี้ต่อไป');
    } else if (todayCompletionRate >= 0.5) {
      insights.add('วันนี้ทำได้ปานกลาง ลองเพิ่มความมั่นใจในตัวเอง');
    } else {
      insights.add('วันนี้อาจจะยุ่งมาก พรุ่งนี้ลองทำดีกว่านี้นะ');
    }

    if (todaySkippedSessions > todayCompletedSessions) {
      insights
          .add('ข้ามกิจกรรมค่อนข้างบ่อย ลองปรับเวลาแจ้งเตือนให้เหมาะสมกว่านี้');
    }

    if (todaySnoozedSessions > 2) {
      insights.add('เลื่อนการแจ้งเตือนบ่อย อาจจะลองลดช่วงเวลาให้สั้นลง');
    }
  }

  void _generateWeeklyInsights(List<String> insights) {
    if (weeklyTotalSessions == 0) {
      insights.add('สัปดาห์นี้ยังไม่มีกิจกรรม ลองตั้งเป้าหมายเล็กๆ เริ่มต้น');
      return;
    }

    final dailyAverage = weeklyTotalSessions / 7;
    if (dailyAverage >= 5) {
      insights.add(
          'เฉลี่ย ${dailyAverage.toStringAsFixed(1)} ครั้งต่อวัน - ยอดเยี่ยม!');
    } else if (dailyAverage >= 3) {
      insights.add(
          'เฉลี่ย ${dailyAverage.toStringAsFixed(1)} ครั้งต่อวัน - ดีแล้ว');
    } else {
      insights.add(
          'เฉลี่ย ${dailyAverage.toStringAsFixed(1)} ครั้งต่อวัน - ควรเพิ่มขึ้น');
    }

    if (weeklyCompletionRate >= 0.7) {
      insights.add(
          'อัตราความสำเร็จดี การออกกำลังกายสม่ำเสมอจะช่วยลดอาการปวดเมื่อย');
    } else {
      insights.add('ลองหาเวลาที่เหมาะสมกับตัวเองมากกว่านี้');
    }

    // Analyze daily pattern
    final dailyStats = dailyStatsForWeek;
    final maxDay =
        dailyStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    final minDay =
        dailyStats.entries.reduce((a, b) => a.value < b.value ? a : b);

    if (maxDay.value > minDay.value * 2) {
      insights.add('มีการออกกำลังกายไม่สม่ำเสมอ ลองกระจายให้ทั่วทั้งสัปดาห์');
    }
  }

  void _generateMonthlyInsights(List<String> insights) {
    if (monthlyTotalSessions == 0) {
      insights.add('เดือนนี้ยังไม่มีกิจกรรม มาเริ่มต้นใช้งานแอปกันเถอะ');
      return;
    }

    insights.add('ในเดือนนี้มี ${activeDaysThisMonth} วันที่มีการออกกำลังกาย');

    final dailyAvg = averageSessionsPerDay;
    if (dailyAvg >= 4) {
      insights.add(
          'เฉลี่ย ${dailyAvg.toStringAsFixed(1)} ครั้งต่อวัน - สุดยอด! 🎉');
    } else if (dailyAvg >= 2) {
      insights
          .add('เฉลี่ย ${dailyAvg.toStringAsFixed(1)} ครั้งต่อวัน - ดีมาก!');
    } else {
      insights.add(
          'เฉลี่ย ${dailyAvg.toStringAsFixed(1)} ครั้งต่อวัน - ยังพอปรับปรุงได้');
    }

    // Analyze monthly trends
    final trends = weeklyTrends;
    if (trends.length >= 2) {
      final thisWeek = trends[4] ?? 0;
      final lastWeek = trends[3] ?? 0;

      if (thisWeek > lastWeek) {
        insights.add('สัปดาห์นี้ทำได้มากขึ้น แสดงว่าเริ่มเข้าสู่จังหวะแล้ว');
      } else if (thisWeek < lastWeek) {
        insights.add('สัปดาห์นี้ลดลงไป ลองหาแรงจูงใจใหม่');
      }
    }

    if (monthlyCompletionRate >= 0.8) {
      insights.add('อัตราความสำเร็จสูงมาก น่าจะช่วยลดอาการปวดเมื่อยได้มาก');
    } else if (monthlyCompletionRate >= 0.6) {
      insights.add('อัตราความสำเร็จดี แต่ยังปรับปรุงได้อีก');
    } else {
      insights.add('อัตราความสำเร็จยังต่ำ ลองหาเวลาที่เหมาะสมกว่านี้');
    }

    // Long-term health benefits
    if (monthlyCompletedSessions >= 50) {
      insights.add('ทำครบ 50 ครั้งแล้ว! ร่างกายน่าจะแข็งแรงขึ้นเยอะ');
    } else if (monthlyCompletedSessions >= 30) {
      insights.add('ใกล้ครบ 50 ครั้งแล้ว พยายามต่อไป!');
    }
  }

  /// Get best performing day of the week
  String getBestPerformingDay() {
    const dayNames = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์'
    ];
    final dayStats = <int, int>{};

    // Initialize all days with 0
    for (int i = 0; i < 7; i++) {
      dayStats[i] = 0;
    }

    // Count completed sessions by day of week
    for (final session in _monthlySessions) {
      if (session.status == SessionStatusHive.completed) {
        final weekday = session.scheduledTime.weekday % 7;
        dayStats[weekday] = (dayStats[weekday] ?? 0) + 1;
      }
    }

    if (dayStats.values.every((count) => count == 0)) {
      return 'ยังไม่มีข้อมูล';
    }

    final bestDay =
        dayStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return dayNames[bestDay.key];
  }

  /// Get worst performing day of the week
  String getWorstPerformingDay() {
    const dayNames = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์'
    ];
    final dayStats = <int, int>{};

    // Initialize all days with 0
    for (int i = 0; i < 7; i++) {
      dayStats[i] = 0;
    }

    // Count completed sessions by day of week
    for (final session in _monthlySessions) {
      if (session.status == SessionStatusHive.completed) {
        final weekday = session.scheduledTime.weekday % 7;
        dayStats[weekday] = (dayStats[weekday] ?? 0) + 1;
      }
    }

    if (dayStats.values.every((count) => count == 0)) {
      return 'ยังไม่มีข้อมูล';
    }

    final worstDay =
        dayStats.entries.reduce((a, b) => a.value < b.value ? a : b);
    return dayNames[worstDay.key];
  }

  /// Get peak activity hour
  String getPeakActivityHour() {
    final hourStats = <int, int>{};

    // Count completed sessions by hour
    for (final session in _monthlySessions) {
      if (session.status == SessionStatusHive.completed) {
        final hour = session.scheduledTime.hour;
        hourStats[hour] = (hourStats[hour] ?? 0) + 1;
      }
    }

    if (hourStats.isEmpty) {
      return 'ยังไม่มีข้อมูล';
    }

    final peakHour =
        hourStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${peakHour.key.toString().padLeft(2, '0')}:00';
  }

  /// Get completion rate by time of day
  Map<String, double> getCompletionRateByTimeOfDay() {
    final timeSlots = <String, List<bool>>{
      'เช้า (6-12)': [],
      'บ่าย (12-18)': [],
      'เย็น (18-24)': [],
    };

    for (final session in _monthlySessions) {
      final hour = session.scheduledTime.hour;
      final completed = session.status == SessionStatusHive.completed;

      if (hour >= 6 && hour < 12) {
        timeSlots['เช้า (6-12)']!.add(completed);
      } else if (hour >= 12 && hour < 18) {
        timeSlots['บ่าย (12-18)']!.add(completed);
      } else if (hour >= 18 && hour < 24) {
        timeSlots['เย็น (18-24)']!.add(completed);
      }
    }

    final rates = <String, double>{};
    for (final entry in timeSlots.entries) {
      if (entry.value.isEmpty) {
        rates[entry.key] = 0.0;
      } else {
        final completed = entry.value.where((c) => c).length;
        rates[entry.key] = completed / entry.value.length;
      }
    }

    return rates;
  }

  /// Calculate streak (consecutive days with completed sessions)
  int getCurrentStreak() {
    if (_monthlySessions.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final hasCompletedSession = _monthlySessions.any((session) =>
          session.scheduledTime.year == day.year &&
          session.scheduledTime.month == day.month &&
          session.scheduledTime.day == day.day &&
          session.status == SessionStatusHive.completed);

      if (hasCompletedSession) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get longest streak this month
  int getLongestStreak() {
    if (_monthlySessions.isEmpty) return 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final dailyCompletion = <bool>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final hasCompleted = _monthlySessions.any((session) =>
          session.scheduledTime.year == date.year &&
          session.scheduledTime.month == date.month &&
          session.scheduledTime.day == date.day &&
          session.status == SessionStatusHive.completed);
      dailyCompletion.add(hasCompleted);
    }

    int maxStreak = 0;
    int currentStreak = 0;

    for (final completed in dailyCompletion) {
      if (completed) {
        currentStreak++;
        maxStreak = maxStreak < currentStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  /// Get summary statistics
  Map<String, dynamic> getSummaryStats() {
    return {
      // Current period stats
      'todayTotal': todayTotalSessions,
      'todayCompleted': todayCompletedSessions,
      'todayRate': todayCompletionRate,

      'weeklyTotal': weeklyTotalSessions,
      'weeklyCompleted': weeklyCompletedSessions,
      'weeklyRate': weeklyCompletionRate,

      'monthlyTotal': monthlyTotalSessions,
      'monthlyCompleted': monthlyCompletedSessions,
      'monthlyRate': monthlyCompletionRate,

      // Derived stats
      'activeDays': activeDaysThisMonth,
      'avgPerDay': averageSessionsPerDay,
      'currentStreak': getCurrentStreak(),
      'longestStreak': getLongestStreak(),

      // Performance analysis
      'bestDay': getBestPerformingDay(),
      'worstDay': getWorstPerformingDay(),
      'peakHour': getPeakActivityHour(),
      'timeSlotRates': getCompletionRateByTimeOfDay(),
    };
  }

  /// Export statistics data
  Map<String, dynamic> exportStatistics() {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'period': '30 days',
      'summary': getSummaryStats(),
      'sessions': _monthlySessions
          .map((session) => {
                'id': session.id,
                'scheduledTime': session.scheduledTime.toIso8601String(),
                'painPointId': session.painPointId,
                'treatmentIds': session.treatmentIds,
                'status': session.status.name,
                'completedTime': session.completedTime?.toIso8601String(),
                'snoozeCount': session.snoozeCount,
              })
          .toList(),
    };
  }

  /// Check if today's goal is met (configurable)
  bool isTodayGoalMet({int goalSessions = 3}) {
    return todayCompletedSessions >= goalSessions;
  }

  /// Check if weekly goal is met (configurable)
  bool isWeeklyGoalMet({int goalSessions = 15}) {
    return weeklyCompletedSessions >= goalSessions;
  }

  /// Get motivational message based on performance
  String getMotivationalMessage() {
    final todayRate = todayCompletionRate;
    final weeklyRate = weeklyCompletionRate;
    final currentStreak = getCurrentStreak();

    if (currentStreak >= 7) {
      return '🔥 Streak ${currentStreak} วัน! คุณเจ็บมาก!';
    } else if (currentStreak >= 3) {
      return '⭐ ทำได้ดี! Streak ${currentStreak} วันแล้ว';
    }

    if (todayRate == 1.0 && todayTotalSessions > 0) {
      return '🎯 วันนี้เพอร์เฟ็ค! ทำได้ทุกครั้ง';
    } else if (weeklyRate >= 0.8) {
      return '💪 สัปดาห์นี้แข็งแรงมาก เก่งจริงๆ';
    } else if (weeklyRate >= 0.6) {
      return '👍 ทำได้ดี แต่ยังปรับปรุงได้อีก';
    } else if (weeklyRate >= 0.3) {
      return '📈 กำลังดีขึ้น มาพยายามต่อกัน';
    } else {
      return '🚀 มาเริ่ม แค่เล็กน้อยก็มีผลแล้ว';
    }
  }

  /// Reset all statistics (for testing)
  Future<void> resetStatistics() async {
    try {
      _todaySessions.clear();
      _weeklySessions.clear();
      _monthlySessions.clear();

      debugPrint('📊 Statistics reset');
    } catch (e) {
      debugPrint('❌ Error resetting statistics: $e');
    }
  }
}
