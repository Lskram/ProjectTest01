import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/notification_session.dart';
import '../services/database_service.dart';

class StatisticsController extends GetxController {
  static StatisticsController get instance => Get.find();

  // Reactive variables
  final _todayStats = <String, dynamic>{}.obs;
  final _weeklyStats = <String, dynamic>{}.obs;
  final _isLoading = false.obs;

  // Getters
  Map<String, dynamic> get todayStats => _todayStats;
  Map<String, dynamic> get weeklyStats => _weeklyStats;
  bool get isLoading => _isLoading.value;

  // Today's statistics
  int get todayTotalSessions => todayStats['totalSessions'] ?? 0;
  int get todayCompletedSessions => todayStats['completedSessions'] ?? 0;
  int get todaySkippedSessions => todayStats['skippedSessions'] ?? 0;
  int get todaySnoozedSessions => todayStats['snoozedSessions'] ?? 0;
  double get todayCompletionRate => todayStats['completionRate'] ?? 0.0;

  // Weekly statistics
  int get weeklyTotalSessions => weeklyStats['totalSessions'] ?? 0;
  int get weeklyCompletedSessions => weeklyStats['completedSessions'] ?? 0;
  double get weeklyCompletionRate => weeklyStats['completionRate'] ?? 0.0;
  Map<DateTime, Map<String, int>> get dailyStats =>
      weeklyStats['dailyStats'] ?? <DateTime, Map<String, int>>{};

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  /// Load all statistics
  Future<void> loadStatistics() async {
    try {
      _isLoading.value = true;

      // Load today's stats
      final todayData = DatabaseService.instance.getTodayStats();
      _todayStats.assignAll(todayData);

      // Load weekly stats
      final weeklyData = DatabaseService.instance.getWeeklyStats();
      _weeklyStats.assignAll(weeklyData);

      debugPrint('✅ Statistics loaded');
    } catch (e) {
      debugPrint('❌ Load statistics error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get sessions for specific date
  List<NotificationSession> getSessionsForDate(DateTime date) {
    return DatabaseService.instance.getSessionsForDate(date);
  }

  /// Get completion rate for specific date
  double getCompletionRateForDate(DateTime date) {
    final sessions = getSessionsForDate(date);
    if (sessions.isEmpty) return 0.0;

    final completedCount = sessions.where((s) => s.isCompleted).length;
    return completedCount / sessions.length;
  }

  /// Get most common pain point this week
  String getMostCommonPainPoint() {
    final sessions = DatabaseService.instance.getSessionsForLastWeek();
    if (sessions.isEmpty) return 'ไม่มีข้อมูล';

    final painPointCounts = <int, int>{};
    for (final session in sessions) {
      painPointCounts[session.painPointId] =
          (painPointCounts[session.painPointId] ?? 0) + 1;
    }

    if (painPointCounts.isEmpty) return 'ไม่มีข้อมูล';

    // Find most common pain point
    final mostCommonId =
        painPointCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final painPoint = DatabaseService.instance
        .getAllPainPoints()
        .where((p) => p.id == mostCommonId)
        .firstOrNull;

    return painPoint?.name ?? 'ไม่ทราบ';
  }

  /// Get best time of day (highest completion rate)
  String getBestTimeOfDay() {
    final sessions = DatabaseService.instance
        .getSessionsForLastWeek()
        .where((s) => s.isCompleted)
        .toList();

    if (sessions.isEmpty) return 'ไม่มีข้อมูล';

    // Group by hour
    final hourCounts = <int, int>{};
    for (final session in sessions) {
      final hour = session.scheduledTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return 'ไม่มีข้อมูล';

    // Find best hour
    final bestHour =
        hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return '${bestHour.toString().padLeft(2, '0')}:00-${(bestHour + 1).toString().padLeft(2, '0')}:00';
  }

  /// Get average session duration
  String getAverageSessionDuration() {
    final completedSessions = DatabaseService.instance
        .getSessionsForLastWeek()
        .where((s) => s.sessionDuration != null)
        .toList();

    if (completedSessions.isEmpty) return 'ไม่มีข้อมูล';

    final totalDuration = completedSessions
        .map((s) => s.sessionDuration!.inSeconds)
        .reduce((a, b) => a + b);

    final averageSeconds = totalDuration / completedSessions.length;
    final averageMinutes = (averageSeconds / 60).round();

    if (averageMinutes < 1) {
      return '${averageSeconds.round()} วินาที';
    } else {
      return '$averageMinutes นาที';
    }
  }

  /// Get weekly trend (improving, declining, stable)
  String getWeeklyTrend() {
    final sessions = DatabaseService.instance.getSessionsForLastWeek();
    if (sessions.length < 2) return 'ไม่เพียงพอ';

    // Split into first half and second half of week
    final midPoint = sessions.length ~/ 2;
    final firstHalf = sessions.sublist(0, midPoint);
    final secondHalf = sessions.sublist(midPoint);

    final firstHalfRate = firstHalf.isNotEmpty
        ? firstHalf.where((s) => s.isCompleted).length / firstHalf.length
        : 0.0;
    final secondHalfRate = secondHalf.isNotEmpty
        ? secondHalf.where((s) => s.isCompleted).length / secondHalf.length
        : 0.0;

    final difference = secondHalfRate - firstHalfRate;

    if (difference > 0.1) {
      return 'ดีขึ้น 📈';
    } else if (difference < -0.1) {
      return 'ลดลง 📉';
    } else {
      return 'คงที่ 📊';
    }
  }

  /// Get streak (consecutive days with completed sessions)
  int getCurrentStreak() {
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      // Check last 30 days
      final date = today.subtract(Duration(days: i));
      final sessions = getSessionsForDate(date);

      if (sessions.isNotEmpty && sessions.any((s) => s.isCompleted)) {
        streak++;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  /// Get weekly completion rates for chart
  List<Map<String, dynamic>> getWeeklyChartData() {
    final chartData = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final sessions = getSessionsForDate(date);
      final completionRate = getCompletionRateForDate(date);

      chartData.add({
        'date': date,
        'day': _getDayName(date.weekday),
        'total': sessions.length,
        'completed': sessions.where((s) => s.isCompleted).length,
        'rate': completionRate,
      });
    }

    return chartData;
  }

  /// Get pain point usage statistics
  Map<String, int> getPainPointUsage() {
    final sessions = DatabaseService.instance.getSessionsForLastWeek();
    final usage = <String, int>{};

    for (final session in sessions) {
      final painPoint = DatabaseService.instance
          .getAllPainPoints()
          .where((p) => p.id == session.painPointId)
          .firstOrNull;

      if (painPoint != null) {
        usage[painPoint.name] = (usage[painPoint.name] ?? 0) + 1;
      }
    }

    return usage;
  }

  /// Get hourly distribution
  Map<int, int> getHourlyDistribution() {
    final sessions = DatabaseService.instance.getSessionsForLastWeek();
    final distribution = <int, int>{};

    for (final session in sessions) {
      final hour = session.scheduledTime.hour;
      distribution[hour] = (distribution[hour] ?? 0) + 1;
    }

    return distribution;
  }

  /// Export statistics as text
  String exportStatistics() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Office Syndrome Helper - สถิติการใช้งาน');
    buffer.writeln('=' * 50);
    buffer.writeln();

    buffer.writeln('📅 วันนี้:');
    buffer.writeln('  • แจ้งเตือนทั้งหมด: $todayTotalSessions ครั้ง');
    buffer.writeln('  • ทำเสร็จ: $todayCompletedSessions ครั้ง');
    buffer.writeln('  • ข้าม: $todaySkippedSessions ครั้ง');
    buffer.writeln('  • เลื่อน: $todaySnoozedSessions ครั้ง');
    buffer.writeln(
        '  • อัตราความสำเร็จ: ${(todayCompletionRate * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    buffer.writeln('📈 สัปดาห์นี้:');
    buffer.writeln('  • แจ้งเตือนทั้งหมด: $weeklyTotalSessions ครั้ง');
    buffer.writeln('  • ทำเสร็จ: $weeklyCompletedSessions ครั้ง');
    buffer.writeln(
        '  • อัตราความสำเร็จ: ${(weeklyCompletionRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('  • จุดที่ดูแลบ่อยสุด: ${getMostCommonPainPoint()}');
    buffer.writeln('  • ช่วงเวลาที่ดีสุด: ${getBestTimeOfDay()}');
    buffer.writeln('  • เวลาเฉลี่ยต่อครั้ง: ${getAverageSessionDuration()}');
    buffer.writeln('  • แนวโน้ม: ${getWeeklyTrend()}');
    buffer.writeln('  • Streak: ${getCurrentStreak()} วัน');
    buffer.writeln();

    buffer.writeln('สร้างเมื่อ: ${DateTime.now()}');

    return buffer.toString();
  }

  /// Refresh statistics
  @override
  Future<void> refresh() async {
    await loadStatistics();
  }

  /// Clear old statistics (keep only last 30 days)
  Future<void> cleanupOldData() async {
    try {
      await DatabaseService.instance.cleanupOldSessions();
      await loadStatistics();

      Get.snackbar('ล้างข้อมูลแล้ว', 'ลบข้อมูลเก่าที่เก็บไว้เกิน 30 วัน');
    } catch (e) {
      debugPrint('❌ Cleanup error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Get day name in Thai
  String _getDayName(int day) {
    const dayNames = {
      1: 'จ',
      2: 'อ',
      3: 'พ',
      4: 'พฤ',
      5: 'ศ',
      6: 'ส',
      7: 'อา',
    };
    return dayNames[day] ?? '';
  }

  /// Get motivation message based on stats
  String getMotivationMessage() {
    final completionRate = todayCompletionRate;
    final streak = getCurrentStreak();

    if (streak >= 7) {
      return 'เยี่ยมมาก! 🔥 คุณดูแลสุขภาพมาแล้ว $streak วันติดต่อกัน!';
    } else if (completionRate >= 0.8) {
      return 'ทำได้ดีมาก! 💪 วันนี้ทำครบ ${(completionRate * 100).toInt()}% แล้ว';
    } else if (completionRate >= 0.5) {
      return 'กำลังใจให้! 😊 อีกนิดนึงก็ครบเป้าแล้ว';
    } else if (completionRate > 0) {
      return 'เริ่มต้นที่ดี! 🌱 ทำต่อเนื่องจะดีต่อสุขภาพ';
    } else {
      return 'มาเริ่มดูแลสุขภาพกันเถอะ! 🚀 แค่ 2-3 นาทีก็ได้ผล';
    }
  }
}
