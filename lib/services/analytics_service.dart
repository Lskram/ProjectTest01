import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/notification_session.dart';
import '../services/database_service.dart';
import '../services/error_service.dart';
import '../utils/date_helper.dart';

/// Local analytics service (no external tracking)
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  /// Track user action (local only)
  Future<void> trackAction(String action,
      {Map<String, dynamic>? properties}) async {
    try {
      if (!kDebugMode) return; // Only track in debug mode for development

      final event = {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'properties': properties ?? {},
      };

      debugPrint('📊 Analytics: ${jsonEncode(event)}');

      // In a real implementation, you might store these locally
      // await _storeEventLocally(event);
    } catch (e) {
      debugPrint('❌ Error tracking action: $e');
    }
  }

  /// Get user engagement metrics
  Future<Map<String, dynamic>> getUserEngagement() async {
    try {
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 30);

      final totalSessions = sessions.length;
      final completedSessions =
          sessions.where((s) => s.status == SessionStatusHive.completed).length;
      final skippedSessions =
          sessions.where((s) => s.status == SessionStatusHive.skipped).length;

      final completionRate =
          totalSessions > 0 ? completedSessions / totalSessions : 0.0;

      // Calculate streak
      final currentStreak = _calculateCurrentStreak(sessions);
      final longestStreak = _calculateLongestStreak(sessions);

      // Calculate average sessions per day
      final activeDays = _getActiveDays(sessions);
      final avgSessionsPerDay =
          activeDays > 0 ? totalSessions / activeDays : 0.0;

      return {
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'skippedSessions': skippedSessions,
        'completionRate': completionRate,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'activeDays': activeDays,
        'avgSessionsPerDay': avgSessionsPerDay,
        'engagementScore': _calculateEngagementScore(
          completionRate,
          currentStreak,
          avgSessionsPerDay,
        ),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error getting user engagement',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Get usage patterns
  Future<Map<String, dynamic>> getUsagePatterns() async {
    try {
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 30);

      // Time slot analysis
      final timeSlots = DateHelper.calculateTimeSlotStats(
        sessions.map((s) => s.scheduledTime).toList(),
      );

      // Day of week analysis
      final dayOfWeekStats = _calculateDayOfWeekStats(sessions);

      // Peak usage hours
      final hourlyStats = _calculateHourlyStats(sessions);
      final peakHour = _findPeakHour(hourlyStats);

      // Session duration patterns
      final durationPatterns = _calculateDurationPatterns(sessions);

      return {
        'timeSlots': timeSlots,
        'dayOfWeekStats': dayOfWeekStats,
        'hourlyStats': hourlyStats,
        'peakHour': peakHour,
        'durationPatterns': durationPatterns,
        'preferredTimeSlot': _getPreferredTimeSlot(timeSlots),
        'mostActiveDay': _getMostActiveDay(dayOfWeekStats),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error getting usage patterns',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Get health insights
  Future<Map<String, dynamic>> getHealthInsights() async {
    try {
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 30);
      final completedSessions = sessions
          .where((s) => s.status == SessionStatusHive.completed)
          .toList();

      // Pain point focus analysis
      final painPointStats = _calculatePainPointStats(completedSessions);

      // Treatment effectiveness
      final treatmentStats = _calculateTreatmentStats(completedSessions);

      // Consistency metrics
      final consistencyScore = _calculateConsistencyScore(sessions);

      // Progress indicators
      final progressMetrics = _calculateProgressMetrics(sessions);

      // Health score
      final healthScore = _calculateHealthScore(
        sessions,
        completedSessions,
        consistencyScore,
      );

      return {
        'painPointStats': painPointStats,
        'treatmentStats': treatmentStats,
        'consistencyScore': consistencyScore,
        'progressMetrics': progressMetrics,
        'healthScore': healthScore,
        'recommendations': _generateRecommendations(sessions, painPointStats),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error getting health insights',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Calculate current streak
  int _calculateCurrentStreak(List<NotificationSession> sessions) {
    if (sessions.isEmpty) return 0;

    final completedSessions = sessions
        .where((s) => s.status == SessionStatusHive.completed)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    if (completedSessions.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final hasSession = completedSessions.any((session) =>
          DateHelper.isToday(session.scheduledTime) &&
          session.scheduledTime.day == date.day);

      if (hasSession) {
        streak++;
      } else if (i > 0) {
        // Allow for today to not have a session yet
        break;
      }
    }

    return streak;
  }

  /// Calculate longest streak
  int _calculateLongestStreak(List<NotificationSession> sessions) {
    if (sessions.isEmpty) return 0;

    final completedSessions = sessions
        .where((s) => s.status == SessionStatusHive.completed)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (completedSessions.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    final dailySessions = <String, bool>{};

    // Group by date
    for (final session in completedSessions) {
      final dateKey = DateHelper.formatThaiShortDate(session.scheduledTime);
      dailySessions[dateKey] = true;
    }

    // Calculate streaks
    final sortedDates = dailySessions.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      if (i == 0) {
        currentStreak = 1;
      } else {
        final currentDate = DateTime.parse(sortedDates[i]);
        final previousDate = DateTime.parse(sortedDates[i - 1]);
        final difference = currentDate.difference(previousDate).inDays;

        if (difference == 1) {
          currentStreak++;
        } else {
          maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
          currentStreak = 1;
        }
      }
    }

    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  /// Get active days count
  int _getActiveDays(List<NotificationSession> sessions) {
    final uniqueDays = <String>{};

    for (final session in sessions) {
      final dateKey = DateHelper.formatThaiShortDate(session.scheduledTime);
      uniqueDays.add(dateKey);
    }

    return uniqueDays.length;
  }

  /// Calculate engagement score (0-100)
  double _calculateEngagementScore(
    double completionRate,
    int currentStreak,
    double avgSessionsPerDay,
  ) {
    // Weighted scoring
    final completionScore = completionRate * 40; // 40% weight
    final streakScore = (currentStreak / 30).clamp(0.0, 1.0) * 30; // 30% weight
    final frequencyScore =
        (avgSessionsPerDay / 5).clamp(0.0, 1.0) * 30; // 30% weight

    return (completionScore + streakScore + frequencyScore).clamp(0.0, 100.0);
  }

  /// Calculate day of week statistics
  Map<String, int> _calculateDayOfWeekStats(
      List<NotificationSession> sessions) {
    final stats = <String, int>{
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (final session in sessions) {
      if (session.status == SessionStatusHive.completed) {
        final dayName = dayNames[session.scheduledTime.weekday - 1];
        stats[dayName] = (stats[dayName] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Calculate hourly statistics
  Map<int, int> _calculateHourlyStats(List<NotificationSession> sessions) {
    final stats = <int, int>{};

    for (final session in sessions) {
      if (session.status == SessionStatusHive.completed) {
        final hour = session.scheduledTime.hour;
        stats[hour] = (stats[hour] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Find peak usage hour
  int _findPeakHour(Map<int, int> hourlyStats) {
    if (hourlyStats.isEmpty) return 12;

    int peakHour = 12;
    int maxCount = 0;

    for (final entry in hourlyStats.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        peakHour = entry.key;
      }
    }

    return peakHour;
  }

  /// Calculate session duration patterns
  Map<String, dynamic> _calculateDurationPatterns(
      List<NotificationSession> sessions) {
    final durations = <int>[];

    for (final session in sessions) {
      if (session.status == SessionStatusHive.completed &&
          session.actualStartTime != null &&
          session.completedTime != null) {
        final duration = session.completedTime!
            .difference(session.actualStartTime!)
            .inMinutes;
        durations.add(duration);
      }
    }

    if (durations.isEmpty) {
      return {
        'averageDuration': 0,
        'minDuration': 0,
        'maxDuration': 0,
        'commonDuration': 0,
      };
    }

    durations.sort();

    final average = durations.reduce((a, b) => a + b) / durations.length;
    final min = durations.first;
    final max = durations.last;
    final median = durations[durations.length ~/ 2];

    return {
      'averageDuration': average.round(),
      'minDuration': min,
      'maxDuration': max,
      'medianDuration': median,
      'totalSamples': durations.length,
    };
  }

  /// Get preferred time slot
  String _getPreferredTimeSlot(Map<String, int> timeSlots) {
    String preferredSlot = 'เช้า';
    int maxCount = 0;

    for (final entry in timeSlots.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        preferredSlot = _translateTimeSlot(entry.key);
      }
    }

    return preferredSlot;
  }

  /// Get most active day
  String _getMostActiveDay(Map<String, int> dayStats) {
    String mostActiveDay = 'จันทร์';
    int maxCount = 0;

    final dayTranslations = {
      'Monday': 'จันทร์',
      'Tuesday': 'อังคาร',
      'Wednesday': 'พุธ',
      'Thursday': 'พฤหัสบดี',
      'Friday': 'ศุกร์',
      'Saturday': 'เสาร์',
      'Sunday': 'อาทิตย์',
    };

    for (final entry in dayStats.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostActiveDay = dayTranslations[entry.key] ?? entry.key;
      }
    }

    return mostActiveDay;
  }

  /// Translate time slot to Thai
  String _translateTimeSlot(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return 'เช้า';
      case 'afternoon':
        return 'บ่าย';
      case 'evening':
        return 'เย็น';
      case 'night':
        return 'กลางคืน';
      default:
        return timeSlot;
    }
  }

  /// Calculate pain point statistics
  Map<String, dynamic> _calculatePainPointStats(
      List<NotificationSession> sessions) {
    final painPointCounts = <int, int>{};
    final painPointNames = <int, String>{
      1: 'ศีรษะ',
      2: 'ตา',
      3: 'คอ',
      4: 'บ่าและไหล่',
      5: 'หลังส่วนบน',
      6: 'หลังส่วนล่าง',
      7: 'แขน/ศอก',
      8: 'ข้อมือ/มือ/นิ้ว',
      9: 'ขา',
      10: 'เท้า',
    };

    for (final session in sessions) {
      painPointCounts[session.painPointId] =
          (painPointCounts[session.painPointId] ?? 0) + 1;
    }

    final sortedPainPoints = painPointCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'counts': painPointCounts,
      'names': painPointNames,
      'mostTreated': sortedPainPoints.isNotEmpty
          ? painPointNames[sortedPainPoints.first.key]
          : 'ไม่มีข้อมูล',
      'leastTreated': sortedPainPoints.isNotEmpty
          ? painPointNames[sortedPainPoints.last.key]
          : 'ไม่มีข้อมูล',
      'totalTreatments': sessions.length,
    };
  }

  /// Calculate treatment statistics
  Map<String, dynamic> _calculateTreatmentStats(
      List<NotificationSession> sessions) {
    final treatmentCounts = <int, int>{};
    int totalTreatments = 0;

    for (final session in sessions) {
      for (final treatmentId in session.treatmentIds) {
        treatmentCounts[treatmentId] = (treatmentCounts[treatmentId] ?? 0) + 1;
        totalTreatments++;
      }
    }

    final sortedTreatments = treatmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'counts': treatmentCounts,
      'totalTreatments': totalTreatments,
      'uniqueTreatments': treatmentCounts.keys.length,
      'mostUsed':
          sortedTreatments.isNotEmpty ? sortedTreatments.first.key : null,
      'averagePerSession':
          sessions.isNotEmpty ? totalTreatments / sessions.length : 0.0,
    };
  }

  /// Calculate consistency score
  double _calculateConsistencyScore(List<NotificationSession> sessions) {
    if (sessions.length < 7) return 0.0; // Need at least a week of data

    final last7Days = sessions
        .where((session) => session.scheduledTime
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    final activeDaysLastWeek = _getActiveDays(last7Days);
    final completedLastWeek =
        last7Days.where((s) => s.status == SessionStatusHive.completed).length;

    final consistency = (activeDaysLastWeek / 7) * 0.6 +
        (completedLastWeek / last7Days.length) * 0.4;

    return (consistency * 100).clamp(0.0, 100.0);
  }

  /// Calculate progress metrics
  Map<String, dynamic> _calculateProgressMetrics(
      List<NotificationSession> sessions) {
    final thisWeek = sessions
        .where((session) => session.scheduledTime
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    final lastWeek = sessions.where((session) {
      final start = DateTime.now().subtract(const Duration(days: 14));
      final end = DateTime.now().subtract(const Duration(days: 7));
      return session.scheduledTime.isAfter(start) &&
          session.scheduledTime.isBefore(end);
    }).toList();

    final thisWeekCompleted =
        thisWeek.where((s) => s.status == SessionStatusHive.completed).length;
    final lastWeekCompleted =
        lastWeek.where((s) => s.status == SessionStatusHive.completed).length;

    final improvement = lastWeekCompleted > 0
        ? (thisWeekCompleted - lastWeekCompleted) / lastWeekCompleted
        : 0.0;

    return {
      'thisWeek': thisWeekCompleted,
      'lastWeek': lastWeekCompleted,
      'improvement': improvement,
      'isImproving': improvement > 0,
      'trend': improvement > 0.1
          ? 'ดีขึ้น'
          : improvement < -0.1
              ? 'แย่ลง'
              : 'คงที่',
    };
  }

  /// Calculate overall health score
  double _calculateHealthScore(
    List<NotificationSession> allSessions,
    List<NotificationSession> completedSessions,
    double consistencyScore,
  ) {
    if (allSessions.isEmpty) return 0.0;

    final completionRate = completedSessions.length / allSessions.length;
    final streakBonus = _calculateCurrentStreak(allSessions) * 2;

    final baseScore =
        (completionRate * 50) + (consistencyScore * 0.3) + streakBonus;

    return baseScore.clamp(0.0, 100.0);
  }

  /// Generate personalized recommendations
  List<String> _generateRecommendations(
    List<NotificationSession> sessions,
    Map<String, dynamic> painPointStats,
  ) {
    final recommendations = <String>[];

    // Completion rate recommendations
    final completedCount =
        sessions.where((s) => s.status == SessionStatusHive.completed).length;
    final completionRate =
        sessions.isNotEmpty ? completedCount / sessions.length : 0.0;

    if (completionRate < 0.3) {
      recommendations
          .add('ลองลดช่วงเวลาแจ้งเตือนให้สั้นลง เพื่อให้ทำได้บ่อยขึ้น');
    } else if (completionRate > 0.8) {
      recommendations.add('ยอดเยี่ยม! คงความสม่ำเสมอนี้ต่อไป');
    }

    // Time pattern recommendations
    final patterns = _calculateDayOfWeekStats(sessions);
    final weekendSessions =
        (patterns['Saturday'] ?? 0) + (patterns['Sunday'] ?? 0);

    if (weekendSessions == 0) {
      recommendations.add('ลองเพิ่มการออกกำลังกายในวันหยุดเสาร์-อาทิตย์');
    }

    // Pain point diversity
    final painPointCounts = painPointStats['counts'] as Map<int, int>? ?? {};
    if (painPointCounts.length < 2) {
      recommendations
          .add('ลองเพิ่มจุดที่ปวดอื่นๆ เพื่อการออกกำลังกายที่หลากหลาย');
    }

    // Streak recommendations
    final currentStreak = _calculateCurrentStreak(sessions);
    if (currentStreak == 0) {
      recommendations
          .add('เริ่มสร้างนิสัยใหม่ ทำต่อเนื่อง 3 วันเพื่อเริ่มสาย streak');
    } else if (currentStreak < 7) {
      recommendations.add('ใกล้ครบ 1 สัปดาห์แล้ว! พยายามต่อไป');
    }

    return recommendations.take(3).toList(); // Limit to 3 recommendations
  }

  /// Get weekly summary
  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 7);
      final engagement = await getUserEngagement();
      final patterns = await getUsagePatterns();

      return {
        'period': 'สัปดาห์นี้',
        'totalSessions': sessions.length,
        'completedSessions': sessions
            .where((s) => s.status == SessionStatusHive.completed)
            .length,
        'completionRate': engagement['completionRate'] ?? 0.0,
        'activeDays': _getActiveDays(sessions),
        'preferredTime': patterns['preferredTimeSlot'] ?? 'ไม่ทราบ',
        'streak': engagement['currentStreak'] ?? 0,
        'highlights': _getWeeklyHighlights(sessions, engagement),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error getting weekly summary',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Get weekly highlights
  List<String> _getWeeklyHighlights(
    List<NotificationSession> sessions,
    Map<String, dynamic> engagement,
  ) {
    final highlights = <String>[];

    final completionRate = engagement['completionRate'] ?? 0.0;
    final streak = engagement['currentStreak'] ?? 0;

    if (completionRate >= 0.8) {
      highlights
          .add('🎯 อัตราความสำเร็จสูงมาก ${(completionRate * 100).toInt()}%');
    }

    if (streak >= 7) {
      highlights.add('🔥 Streak ติดต่อกัน $streak วัน');
    }

    final activeDays = _getActiveDays(sessions);
    if (activeDays >= 5) {
      highlights.add('📅 ออกกำลังกาย $activeDays วันในสัปดาห์นี้');
    }

    if (highlights.isEmpty) {
      highlights.add('💪 เริ่มต้นสัปดาห์หน้าด้วยความมุ่งมั่นใหม่');
    }

    return highlights;
  }

  /// Export analytics data
  Future<Map<String, dynamic>> exportAnalytics() async {
    try {
      final engagement = await getUserEngagement();
      final patterns = await getUsagePatterns();
      final health = await getHealthInsights();
      final summary = await getWeeklySummary();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'period': '30 วันที่ผ่านมา',
        'engagement': engagement,
        'patterns': patterns,
        'health': health,
        'summary': summary,
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error exporting analytics',
        e,
        stackTrace,
      );
      return {};
    }
  }
}
