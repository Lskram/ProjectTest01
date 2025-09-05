// lib/services/analytics_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/notification_session.dart';
import '../models/user_settings.dart';
import '../models/pain_point.dart';

/// 📊 Office Syndrome Helper - Local Analytics Service
/// ติดตามสถิติการใช้งานแบบออฟไลน์เท่านั้น (ไม่ส่งข้อมูลไปเซิร์ฟเวอร์)
class AnalyticsService {
  static const String _boxName = 'analytics_box';
  static late Box _analyticsBox;
  
  // Storage Keys
  static const String _keyUsageStats = 'usage_stats';
  static const String _keyDailyStats = 'daily_stats';
  static const String _keyWeeklyStats = 'weekly_stats';
  static const String _keyMonthlyStats = 'monthly_stats';
  static const String _keyPainPointStats = 'pain_point_stats';
  static const String _keySessionHistory = 'session_history';
  static const String _keyAppEvents = 'app_events';
  static const String _keyStreakData = 'streak_data';
  static const String _keyBadges = 'badges';
  static const String _keyGoals = 'goals';

  /// Initialize Analytics Service
  static Future<void> initialize() async {
    try {
      _analyticsBox = await Hive.openBox(_boxName);
      debugPrint('✅ AnalyticsService initialized');
      
      // เริ่มต้นสถิติถ้ายังไม่มี
      await _initializeDefaultStats();
    } catch (e) {
      debugPrint('❌ Error initializing AnalyticsService: $e');
    }
  }

  /// สร้างสถิติเริ่มต้น
  static Future<void> _initializeDefaultStats() async {
    final defaultStats = <String, dynamic>{};
    final defaultList = <Map<String, dynamic>>[];
    
    if (!_analyticsBox.containsKey(_keyUsageStats)) {
      await _analyticsBox.put(_keyUsageStats, defaultStats);
    }
    if (!_analyticsBox.containsKey(_keyDailyStats)) {
      await _analyticsBox.put(_keyDailyStats, defaultStats);
    }
    if (!_analyticsBox.containsKey(_keyPainPointStats)) {
      await _analyticsBox.put(_keyPainPointStats, defaultStats);
    }
    if (!_analyticsBox.containsKey(_keySessionHistory)) {
      await _analyticsBox.put(_keySessionHistory, defaultList);
    }
    if (!_analyticsBox.containsKey(_keyAppEvents)) {
      await _analyticsBox.put(_keyAppEvents, defaultList);
    }
    if (!_analyticsBox.containsKey(_keyStreakData)) {
      await _analyticsBox.put(_keyStreakData, {
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed_date': null,
        'streak_start_date': null,
      });
    }
    if (!_analyticsBox.containsKey(_keyBadges)) {
      await _analyticsBox.put(_keyBadges, defaultList);
    }
    if (!_analyticsBox.containsKey(_keyGoals)) {
      await _analyticsBox.put(_keyGoals, {
        'daily_goal': 8, // 8 sessions per day
        'weekly_goal': 40, // 40 sessions per week
        'monthly_goal': 160, // 160 sessions per month
      });
    }
  }

  // ========================================
  // 📱 APP EVENTS TRACKING
  // ========================================

  /// บันทึกเหตุการณ์ในแอป
  static Future<void> trackAppEvent(String eventName, {Map<String, dynamic>? properties}) async {
    try {
      final event = {
        'event_name': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        'properties': properties ?? {},
      };
      
      final events = List<Map<String, dynamic>>.from(_analyticsBox.get(_keyAppEvents) ?? []);
      events.add(event);
      
      // เก็บเฉพาะ 1000 events ล่าสุด
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }
      
      await _analyticsBox.put(_keyAppEvents, events);
      debugPrint('📊 App event tracked: $eventName');
    } catch (e) {
      debugPrint('❌ Error tracking app event: $e');
    }
  }

  /// รับประวัติเหตุการณ์ในแอป
  static List<Map<String, dynamic>> getAppEvents({int limit = 100}) {
    try {
      final events = List<Map<String, dynamic>>.from(_analyticsBox.get(_keyAppEvents) ?? []);
      
      // เรียงตามวันที่ล่าสุด
      events.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      return events.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting app events: $e');
      return [];
    }
  }

  // ========================================
  // 🏋️ EXERCISE SESSION TRACKING
  // ========================================

  /// บันทึกการทำท่าออกกำลังกาย
  static Future<void> trackExerciseSession(NotificationSession session) async {
    try {
      final sessionData = {
        'session_id': session.id,
        'timestamp': session.timestamp.toIso8601String(),
        'pain_point': session.painPoint,
        'treatments': session.treatments.map((t) => t.toJson()).toList(),
        'status': session.status,
        'completed_at': session.completedAt?.toIso8601String(),
        'duration_minutes': session.durationMinutes,
        'snooze_count': session.snoozeCount,
      };
      
      // บันทึกในประวัติเซสชัน
      final history = List<Map<String, dynamic>>.from(_analyticsBox.get(_keySessionHistory) ?? []);
      history.add(sessionData);
      
      // เก็บเฉพาะ 500 sessions ล่าสุด
      if (history.length > 500) {
        history.removeRange(0, history.length - 500);
      }
      
      await _analyticsBox.put(_keySessionHistory, history);
      
      // อัปเดตสถิติ
      await _updateDailyStats(session);
      await _updatePainPointStats(session);
      await _updateUsageStats(session);
      await _updateStreakData(session);
      await _checkAndAwardBadges(session);
      
      debugPrint('📊 Exercise session tracked: ${session.id}');
    } catch (e) {
      debugPrint('❌ Error tracking exercise session: $e');
    }
  }

  /// รับประวัติเซสชัน
  static List<Map<String, dynamic>> getSessionHistory({int limit = 50}) {
    try {
      final history = List<Map<String, dynamic>>.from(_analyticsBox.get(_keySessionHistory) ?? []);
      
      // เรียงตามวันที่ล่าสุด
      history.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      
      return history.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting session history: $e');
      return [];
    }
  }

  // ========================================
  // 📈 DAILY STATISTICS
  // ========================================

  /// อัปเดตสถิติรายวัน
  static Future<void> _updateDailyStats(NotificationSession session) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(session.timestamp);
      final dailyStats = Map<String, dynamic>.from(_analyticsBox.get(_keyDailyStats) ?? {});
      
      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = {
          'total_sessions': 0,
          'completed_sessions': 0,
          'skipped_sessions': 0,
          'missed_sessions': 0,
          'total_exercise_time': 0,
          'pain_points': <String, int>{},
          'treatments_used': <String, int>{},
          'hour_distribution': <int, int>{}, // ชั่วโมงที่ทำมากที่สุด
        };
      }
      
      final dayData = dailyStats[dateKey];
      dayData['total_sessions'] = (dayData['total_sessions'] ?? 0) + 1;
      
      // อัปเดตสถานะ
      switch (session.status) {
        case 'completed':
          dayData['completed_sessions'] = (dayData['completed_sessions'] ?? 0) + 1;
          dayData['total_exercise_time'] = (dayData['total_exercise_time'] ?? 0) + (session.durationMinutes ?? 0);
          
          // บันทึกท่าที่ใช้
          final treatmentsUsed = Map<String, int>.from(dayData['treatments_used'] ?? {});
          for (final treatment in session.treatments) {
            treatmentsUsed[treatment.name] = (treatmentsUsed[treatment.name] ?? 0) + 1;
          }
          dayData['treatments_used'] = treatmentsUsed;
          
          // บันทึกชั่วโมงที่ทำ
          final hour = session.completedAt?.hour ?? session.timestamp.hour;
          final hourDist = Map<int, int>.from(dayData['hour_distribution'] ?? {});
          hourDist[hour] = (hourDist[hour] ?? 0) + 1;
          dayData['hour_distribution'] = hourDist;
          break;
          
        case 'skipped':
          dayData['skipped_sessions'] = (dayData['skipped_sessions'] ?? 0) + 1;
          break;
          
        case 'missed':
          dayData['missed_sessions'] = (dayData['missed_sessions'] ?? 0) + 1;
          break;
      }
      
      // นับจุดที่ปวด
      final painPoints = Map<String, int>.from(dayData['pain_points'] ?? {});
      painPoints[session.painPoint] = (painPoints[session.painPoint] ?? 0) + 1;
      dayData['pain_points'] = painPoints;
      
      // คำนวณ completion rate
      dayData['completion_rate'] = dayData['total_sessions'] > 0 
          ? (dayData['completed_sessions'] / dayData['total_sessions']) * 100
          : 0.0;
      
      await _analyticsBox.put(_keyDailyStats, dailyStats);
    } catch (e) {
      debugPrint('❌ Error updating daily stats: $e');
    }
  }

  /// รับสถิติรายวัน
  static Map<String, dynamic> getDailyStats(DateTime date) {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dailyStats = Map<String, dynamic>.from(_analyticsBox.get(_keyDailyStats) ?? {});
      
      return dailyStats[dateKey] ?? {
        'total_sessions': 0,
        'completed_sessions': 0,
        'skipped_sessions': 0,
        'missed_sessions': 0,
        'total_exercise_time': 0,
        'pain_points': <String, int>{},
        'treatments_used': <String, int>{},
        'hour_distribution': <int, int>{},
        'completion_rate': 0.0,
      };
    } catch (e) {
      debugPrint('❌ Error getting daily stats: $e');
      return {};
    }
  }

  // ========================================
  // 📊 WEEKLY STATISTICS
  // ========================================

  /// รับสถิติรายสัปดาห์
  static Map<String, dynamic> getWeeklyStats(DateTime startDate) {
    try {
      final weeklyData = <String, dynamic>{
        'total_sessions': 0,
        'completed_sessions': 0,
        'skipped_sessions': 0,
        'missed_sessions': 0,
        'total_exercise_time': 0,
        'daily_breakdown': <String, Map<String, dynamic>>{},
        'completion_rate': 0.0,
        'most_active_day': '',
        'least_active_day': '',
        'peak_hour': 0,
        'favorite_pain_point': '',
        'favorite_treatment': '',
      };
      
      final allPainPoints = <String, int>{};
      final allTreatments = <String, int>{};
      final allHours = <int, int>{};
      
      int maxSessions = 0;
      int minSessions = 999999;
      String mostActiveDay = '';
      String leastActiveDay = '';
      
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dayStats = getDailyStats(date);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final dayName = DateFormat('EEEE', 'th').format(date);
        
        weeklyData['daily_breakdown'][dateKey] = dayStats;
        weeklyData['total_sessions'] += dayStats['total_sessions'] ?? 0;
        weeklyData['completed_sessions'] += dayStats['completed_sessions'] ?? 0;
        weeklyData['skipped_sessions'] += dayStats['skipped_sessions'] ?? 0;
        weeklyData['missed_sessions'] += dayStats['missed_sessions'] ?? 0;
        weeklyData['total_exercise_time'] += dayStats['total_exercise_time'] ?? 0;
        
        // รวม pain points
        final dayPainPoints = Map<String, int>.from(dayStats['pain_points'] ?? {});
        dayPainPoints.forEach((point, count) {
          allPainPoints[point] = (allPainPoints[point] ?? 0) + count;
        });
        
        // รวม treatments
        final dayTreatments = Map<String, int>.from(dayStats['treatments_used'] ?? {});
        dayTreatments.forEach((treatment, count) {
          allTreatments[treatment] = (allTreatments[treatment] ?? 0) + count;
        });
        
        // รวม hours
        final dayHours = Map<int, int>.from(dayStats['hour_distribution'] ?? {});
        dayHours.forEach((hour, count) {
          allHours[hour] = (allHours[hour] ?? 0) + count;
        });
        
        // หาวันที่ active มากที่สุดและน้อยที่สุด
        final totalSessions = dayStats['total_sessions'] ?? 0;
        if (totalSessions > maxSessions) {
          maxSessions = totalSessions;
          mostActiveDay = dayName;
        }
        if (totalSessions < minSessions) {
          minSessions = totalSessions;
          leastActiveDay = dayName;
        }
      }
      
      weeklyData['most_active_day'] = mostActiveDay;
      weeklyData['least_active_day'] = leastActiveDay;
      
      // หา peak hour
      if (allHours.isNotEmpty) {
        final peakHour = allHours.entries.reduce((a, b) => a.value > b.value ? a : b);
        weeklyData['peak_hour'] = peakHour.key;
      }
      
      // หา favorite pain point
      if (allPainPoints.isNotEmpty) {
        final favoritePainPoint = allPainPoints.entries.reduce((a, b) => a.value > b.value ? a : b);
        weeklyData['favorite_pain_point'] = favoritePainPoint.key;
      }
      
      // หา favorite treatment
      if (allTreatments.isNotEmpty) {
        final favoriteTreatment = allTreatments.entries.reduce((a, b) => a.value > b.value ? a : b);
        weeklyData['favorite_treatment'] = favoriteTreatment.key;
      }
      
      // คำนวณ completion rate
      if (weeklyData['total_sessions'] > 0) {
        weeklyData['completion_rate'] = 
            (weeklyData['completed_sessions'] / weeklyData['total_sessions']) * 100;
      }
      
      return weeklyData;
    } catch (e) {
      debugPrint('❌ Error getting weekly stats: $e');
      return {};
    }
  }

  // ========================================
  // 📅 MONTHLY STATISTICS
  // ========================================

  /// รับสถิติรายเดือน
  static Map<String, dynamic> getMonthlyStats(DateTime month) {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      final monthlyData = <String, dynamic>{
        'total_sessions': 0,
        'completed_sessions': 0,
        'skipped_sessions': 0,
        'missed_sessions': 0,
        'total_exercise_time': 0,
        'weekly_breakdown': <String, Map<String, dynamic>>{},
        'completion_rate': 0.0,
        'most_active_day': '',
        'least_active_day': '',
        'most_active_week': '',
        'improvement_trend': 'stable', // 'improving', 'declining', 'stable'
        'days_with_goals_met': 0,
        'consistency_score': 0.0, // 0-100
      };
      
      DateTime currentDate = startDate;
      int maxSessions = 0;
      int minSessions = 999999;
      String mostActiveDay = '';
      String leastActiveDay = '';
      int daysWithActivity = 0;
      int totalDays = 0;
      final weeklyTotals = <int>[];
      
      // วิเคราะห์ทีละวัน
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final dayStats = getDailyStats(currentDate);
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        
        final totalSessions = dayStats['total_sessions'] ?? 0;
        final completedSessions = dayStats['completed_sessions'] ?? 0;
        
        monthlyData['total_sessions'] += totalSessions;
        monthlyData['completed_sessions'] += completedSessions;
        monthlyData['skipped_sessions'] += dayStats['skipped_sessions'] ?? 0;
        monthlyData['missed_sessions'] += dayStats['missed_sessions'] ?? 0;
        monthlyData['total_exercise_time'] += dayStats['total_exercise_time'] ?? 0;
        
        // นับวันที่มีกิจกรรม
        if (totalSessions > 0) {
          daysWithActivity++;
        }
        
        // ตรวจสอบเป้าหมายรายวัน (8 sessions)
        if (completedSessions >= 8) {
          monthlyData['days_with_goals_met'] = (monthlyData['days_with_goals_met'] ?? 0) + 1;
        }
        
        // หาวันที่ active มากที่สุดและน้อยที่สุด
        if (totalSessions > maxSessions) {
          maxSessions = totalSessions;
          mostActiveDay = DateFormat('dd MMM', 'th').format(currentDate);
        }
        if (totalSessions < minSessions && totalSessions > 0) {
          minSessions = totalSessions;
          leastActiveDay = DateFormat('dd MMM', 'th').format(currentDate);
        }
        
        totalDays++;
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      monthlyData['most_active_day'] = mostActiveDay;
      monthlyData['least_active_day'] = leastActiveDay;
      
      // คำนวณ consistency score
      monthlyData['consistency_score'] = totalDays > 0 ? (daysWithActivity / totalDays) * 100 : 0.0;
      
      // คำนวณ completion rate
      if (monthlyData['total_sessions'] > 0) {
        monthlyData['completion_rate'] = 
            (monthlyData['completed_sessions'] / monthlyData['total_sessions']) * 100;
      }
      
      // วิเคราะห์แนวโน้ม (เปรียบเทียบสัปดาห์แรกกับสัปดาห์สุดท้าย)
      final firstWeekStats = getWeeklyStats(startDate);
      final lastWeekStart = endDate.subtract(Duration(days: 6));
      final lastWeekStats = getWeeklyStats(lastWeekStart);
      
      final firstWeekRate = firstWeekStats['completion_rate'] ?? 0.0;
      final lastWeekRate = lastWeekStats['completion_rate'] ?? 0.0;
      
      if (lastWeekRate > firstWeekRate + 5) {
        monthlyData['improvement_trend'] = 'improving';
      } else if (firstWeekRate > lastWeekRate + 5) {
        monthlyData['improvement_trend'] = 'declining';
      } else {
        monthlyData['improvement_trend'] = 'stable';
      }
      
      return monthlyData;
    } catch (e) {
      debugPrint('❌ Error getting monthly stats: $e');
      return {};
    }
  }

  // ========================================
  // 🎯 PAIN POINT STATISTICS
  // ========================================

  /// อัปเดตสถิติจุดที่ปวด
  static Future<void> _updatePainPointStats(NotificationSession session) async {
    try {
      final painPointStats = Map<String, dynamic>.from(_analyticsBox.get(_keyPainPointStats) ?? {});
      
      if (!painPointStats.containsKey(session.painPoint)) {
        painPointStats[session.painPoint] = {
          'total_sessions': 0,
          'completed_sessions': 0,
          'completion_rate': 0.0,
          'average_duration': 0.0,
          'most_used_treatments': <String, int>{},
          'total_exercise_time': 0,
          'best_day_of_week': '',
          'best_hour': 0,
        };
      }
      
      final pointData = painPointStats[session.painPoint];
      pointData['total_sessions'] = (pointData['total_sessions'] ?? 0) + 1;
      
      if (session.status == 'completed') {
        pointData['completed_sessions'] = (pointData['completed_sessions'] ?? 0) + 1;
        pointData['total_exercise_time'] = (pointData['total_exercise_time'] ?? 0) + (session.durationMinutes ?? 0);
        
        // คำนวณ completion rate
        pointData['completion_rate'] = 
            (pointData['completed_sessions'] / pointData['total_sessions']) * 100;
        
        // คำนวณ average duration
        pointData['average_duration'] = 
            pointData['total_exercise_time'] / pointData['completed_sessions'];
        
        // นับการใช้งานของแต่ละท่า
        final treatments = Map<String, int>.from(pointData['most_used_treatments'] ?? {});
        for (final treatment in session.treatments) {
          treatments[treatment.name] = (treatments[treatment.name] ?? 0) + 1;
        }
        pointData['most_used_treatments'] = treatments;
      }
      
      await _analyticsBox.put(_keyPainPointStats, painPointStats);
    } catch (e) {
      debugPrint('❌ Error updating pain point stats: $e');
    }
  }

  /// รับสถิติจุดที่ปวด
  static Map<String, dynamic> getPainPointStats() {
    try {
      return Map<String, dynamic>.from(_analyticsBox.get(_keyPainPointStats) ?? {});
    } catch (e) {
      debugPrint('❌ Error getting pain point stats: $e');
      return {};
    }
  }

  // ========================================
  // ⚙️ USAGE STATISTICS
  // ========================================

  /// อัปเดตสถิติการใช้งานทั่วไป
  static Future<void> _updateUsageStats(NotificationSession session) async {
    try {
      final usageStats = Map<String, dynamic>.from(_analyticsBox.get(_keyUsageStats) ?? {});
      
      usageStats['total_sessions'] = (usageStats['total_sessions'] ?? 0) + 1;
      usageStats['last_session_date'] = session.timestamp.toIso8601String();
      
      // อัปเดตวันแรกที่ใช้แอป
      if (!usageStats.containsKey('first_session_date')) {
        usageStats['first_session_date'] = session.timestamp.toIso8601String();
      }
      
      switch (session.status) {
        case 'completed':
          usageStats['total_completed'] = (usageStats['total_completed'] ?? 0) + 1;
          usageStats['total_exercise_time'] = (usageStats['total_exercise_time'] ?? 0) + (session.durationMinutes ?? 0);
          break;
        case 'skipped':
          usageStats['total_skipped'] = (usageStats['total_skipped'] ?? 0) + 1;
          break;
        case 'missed':
          usageStats['total_missed'] = (usageStats['total_missed'] ?? 0) + 1;
          break;
      }
      
      // คำนวณ overall completion rate
      final totalCompleted = usageStats['total_completed'] ?? 0;
      final totalSessions = usageStats['total_sessions'] ?? 1;
      usageStats['overall_completion_rate'] = (totalCompleted / totalSessions) * 100;
      
      // คำนวณวันที่ใช้แอป
      final firstDate = DateTime.parse(usageStats['first_session_date']);
      final daysSinceFirst = DateTime.now().difference(firstDate).inDays + 1;
      usageStats['days_since_first_use'] = daysSinceFirst;
      
      // คำนวณเฉลี่ยต่อวัน
      usageStats['average_sessions_per_day'] = totalSessions / daysSinceFirst;
      usageStats['average_completed_per_day'] = totalCompleted / daysSinceFirst;
      
      await _analyticsBox.put(_keyUsageStats, usageStats);
    } catch (e) {
      debugPrint('❌ Error updating usage stats: $e');
    }
  }

  /// รับสถิติการใช้งานทั่วไป
  static Map<String, dynamic> getUsageStats() {
    try {
      return Map<String, dynamic>.from(_analyticsBox.get(_keyUsageStats) ?? {});
    } catch (e) {
      debugPrint('❌ Error getting usage stats: $e');
      return {};
    }
  }

  // ========================================
  // 🔥 STREAK TRACKING
  // ========================================

  /// อัปเดต streak data
  static Future<void> _updateStreakData(NotificationSession session) async {
    try {
      if (session.status != 'completed') return;
      
      final streakData = Map<String, dynamic>.from(_analyticsBox.get(_keyStreakData) ?? {});
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastCompletedDate = streakData['last_completed_date'];
      
      if (lastCompletedDate == null) {
        // วันแรก
        streakData['current_streak'] = 1;
        streakData['longest_streak'] = 1;
        streakData['last_completed_date'] = today;
        streakData['streak_start_date'] = today;
      } else {
        final lastDate = DateTime.parse(lastCompletedDate);
        final todayDate = DateTime.now();
        final daysDiff = todayDate.difference(lastDate).inDays;
        
        if (daysDiff == 1) {
          // ต่อเนื่อง
          final currentStreak = (streakData['current_streak'] ?? 0) + 1;
          streakData['current_streak'] = currentStreak;
          streakData['last_completed_date'] = today;
          
          // อัปเดต longest streak
          final longestStreak = streakData['longest_streak'] ?? 0;
          if (currentStreak > longestStreak) {
            streakData['longest_streak'] = currentStreak;
          }
        } else if (daysDiff > 1) {
          // ขาด - เริ่มใหม่
          streakData['current_streak'] = 1;
          streakData['last_completed_date'] = today;
          streakData['streak_start_date'] = today;
        }
        // daysDiff == 0 แปลว่าทำในวันเดียวกัน ไม่ต้องอัปเดต
      }
      
      await _analyticsBox.put(_keyStreakData, streakData);
    } catch (e) {
      debugPrint('❌ Error updating streak data: $e');
    }
  }

  /// รับข้อมูล streak
  static Map<String, dynamic> getStreakData() {
    try {
      return Map<String, dynamic>.from(_analyticsBox.get(_keyStreakData) ?? {
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed_date': null,
        'streak_start_date': null,
      });
    } catch (e) {
      debugPrint('❌ Error getting streak data: $e');
      return {
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed_date': null,
        'streak_start_date': null,
      };
    }
  }

  // ========================================
  // 🏆 BADGES & ACHIEVEMENTS
  // ========================================

  /// ตรวจสอบและมอบ badges
  static Future<void> _checkAndAwardBadges(NotificationSession session) async {
    try {
      final usageStats = getUsageStats();
      final streakData = getStreakData();
      final badges = List<Map<String, dynamic>>.from(_analyticsBox.get(_keyBadges) ?? []);
      final existingBadgeIds = badges.map((b) => b['id']).toSet();
      
      final totalCompleted = usageStats['total_completed'] ?? 0;
      final currentStreak = streakData['current_streak'] ?? 0;
      final longestStreak = streakData['longest_streak'] ?? 0;
      
      final newBadges = <Map<String, dynamic>>[];
      
      // Completion badges
      final completionBadges = [
        {'id': 'first_step', 'threshold': 1, 'name': 'First Step', 'icon': '🥉', 'description': 'ทำท่าออกกำลังกายครั้งแรก'},
        {'id': 'getting_started', 'threshold': 10, 'name': 'Getting Started', 'icon': '🥈', 'description': 'ทำท่าออกกำลังกาย 10 ครั้ง'},
        {'id': 'committed', 'threshold': 50, 'name': 'Committed', 'icon': '🥇', 'description': 'ทำท่าออกกำลังกาย 50 ครั้ง'},
        {'id': 'dedicated', 'threshold': 100, 'name': 'Dedicated', 'icon': '🏆', 'description': 'ทำท่าออกกำลังกาย 100 ครั้ง'},
        {'id': 'master', 'threshold': 250, 'name': 'Master', 'icon': '💎', 'description': 'ทำท่าออกกำลังกาย 250 ครั้ง'},
        {'id': 'legend', 'threshold': 500, 'name': 'Legend', 'icon': '👑', 'description': 'ทำท่าออกกำลังกาย 500 ครั้ง'},
        {'id': 'ultimate', 'threshold': 1000, 'name': 'Ultimate', 'icon': '🌟', 'description': 'ทำท่าออกกำลังกาย 1000 ครั้ง'},
      ];
      
      for (final badge in completionBadges) {
        if (totalCompleted >= badge['threshold'] && !existingBadgeIds.contains(badge['id'])) {
          newBadges.add({
            ...badge,
            'earned_at': DateTime.now().toIso8601String(),
            'type': 'completion',
          });
        }
      }
      
      // Streak badges
      final streakBadges = [
        {'id': 'streak_3', 'threshold': 3, 'name': '3-Day Streak', 'icon': '🔥', 'description': 'ทำต่อเนื่อง 3 วัน'},
        {'id': 'streak_7', 'threshold': 7, 'name': 'Week Warrior', 'icon': '💪', 'description': 'ทำต่อเนื่อง 7 วัน'},
        {'id': 'streak_14', 'threshold': 14, 'name': 'Two Week Champion', 'icon': '🏅', 'description': 'ทำต่อเนื่อง 14 วัน'},
        {'id': 'streak_30', 'threshold': 30, 'name': 'Monthly Master', 'icon': '⭐', 'description': 'ทำต่อเนื่อง 30 วัน'},
        {'id': 'streak_50', 'threshold': 50, 'name': 'Unstoppable', 'icon': '🚀', 'description': 'ทำต่อเนื่อง 50 วัน'},
        {'id': 'streak_100', 'threshold': 100, 'name': 'Century Club', 'icon': '💫', 'description': 'ทำต่อเนื่อง 100 วัน'},
      ];
      
      for (final badge in streakBadges) {
        if (currentStreak >= badge['threshold'] && !existingBadgeIds.contains(badge['id'])) {
          newBadges.add({
            ...badge,
            'earned_at': DateTime.now().toIso8601String(),
            'type': 'streak',
          });
        }
      }
      
      // Special badges
      final totalSessions = usageStats['total_sessions'] ?? 0;
      final completionRate = usageStats['overall_completion_rate'] ?? 0.0;
      
      final specialBadges = [
        {
          'id': 'perfectionist',
          'condition': () => totalSessions >= 20 && completionRate >= 95,
          'name': 'Perfectionist',
          'icon': '✨',
          'description': 'อัตราความสำเร็จ 95% ใน 20 sessions แรก'
        },
        {
          'id': 'early_bird', 
          'condition': () => _isEarlyBird(),
          'name': 'Early Bird',
          'icon': '🌅',
          'description': 'ทำออกกำลังกายก่อน 8 โมงเช้าเป็นประจำ'
        },
        {
          'id': 'night_owl',
          'condition': () => _isNightOwl(), 
          'name': 'Night Owl',
          'icon': '🌙',
          'description': 'ทำออกกำลังกายหลัง 8 โมงเย็นเป็นประจำ'
        },
        {
          'id': 'pain_fighter',
          'condition': () => _isPainFighter(),
          'name': 'Pain Fighter', 
          'icon': '🥊',
          'description': 'ทำท่าครบทุกจุดที่ปวด'
        },
      ];
      
      for (final badge in specialBadges) {
        if (badge['condition']() && !existingBadgeIds.contains(badge['id'])) {
          newBadges.add({
            'id': badge['id'],
            'name': badge['name'],
            'icon': badge['icon'],
            'description': badge['description'],
            'earned_at': DateTime.now().toIso8601String(),
            'type': 'special',
          });
        }
      }
      
      // บันทึก badges ใหม่
      if (newBadges.isNotEmpty) {
        badges.addAll(newBadges);
        await _analyticsBox.put(_keyBadges, badges);
        
        // Track badge events
        for (final badge in newBadges) {
          await trackAppEvent('badge_earned', properties: {
            'badge_id': badge['id'],
            'badge_name': badge['name'],
            'badge_type': badge['type'],
          });
        }
        
        debugPrint('🏆 New badges earned: ${newBadges.map((b) => b['name']).join(', ')}');
      }
    } catch (e) {
      debugPrint('❌ Error checking badges: $e');
    }
  }

  /// ตรวจสอบว่าเป็น early bird หรือไม่
  static bool _isEarlyBird() {
    try {
      final sessions = getSessionHistory(limit: 20);
      int earlyBirdCount = 0;
      
      for (final session in sessions) {
        if (session['status'] == 'completed' && session['completed_at'] != null) {
          final completedTime = DateTime.parse(session['completed_at']);
          if (completedTime.hour < 8) {
            earlyBirdCount++;
          }
        }
      }
      
      return earlyBirdCount >= 10; // 10 ครั้งจาก 20 ครั้งล่าสุด
    } catch (e) {
      return false;
    }
  }

  /// ตรวจสอบว่าเป็น night owl หรือไม่
  static bool _isNightOwl() {
    try {
      final sessions = getSessionHistory(limit: 20);
      int nightOwlCount = 0;
      
      for (final session in sessions) {
        if (session['status'] == 'completed' && session['completed_at'] != null) {
          final completedTime = DateTime.parse(session['completed_at']);
          if (completedTime.hour >= 20) {
            nightOwlCount++;
          }
        }
      }
      
      return nightOwlCount >= 10; // 10 ครั้งจาก 20 ครั้งล่าสุด
    } catch (e) {
      return false;
    }
  }

  /// ตรวจสอบว่าเป็น pain fighter หรือไม่
  static bool _isPainFighter() {
    try {
      final painPointStats = getPainPointStats();
      final uniquePainPoints = painPointStats.keys.where((key) {
        final stats = painPointStats[key];
        return (stats['completed_sessions'] ?? 0) >= 5; // อย่างน้อย 5 ครั้งต่อจุด
      }).length;
      
      return uniquePainPoints >= 5; // อย่างน้อย 5 จุดที่แตกต่างกัน
    } catch (e) {
      return false;
    }
  }

  /// รับ badges ทั้งหมด
  static List<Map<String, dynamic>> getBadges() {
    try {
      final badges = List<Map<String, dynamic>>.from(_analyticsBox.get(_keyBadges) ?? []);
      // เรียงตามวันที่ได้รับล่าสุด
      badges.sort((a, b) => DateTime.parse(b['earned_at']).compareTo(DateTime.parse(a['earned_at'])));
      return badges;
    } catch (e) {
      debugPrint('❌ Error getting badges: $e');
      return [];
    }
  }

  // ========================================
  // 🎯 GOALS & ACHIEVEMENTS
  // ========================================

  /// ตั้งเป้าหมาย
  static Future<void> setGoals({
    int? dailyGoal,
    int? weeklyGoal, 
    int? monthlyGoal,
  }) async {
    try {
      final goals = Map<String, dynamic>.from(_analyticsBox.get(_keyGoals) ?? {});
      
      if (dailyGoal != null) goals['daily_goal'] = dailyGoal;
      if (weeklyGoal != null) goals['weekly_goal'] = weeklyGoal;
      if (monthlyGoal != null) goals['monthly_goal'] = monthlyGoal;
      
      await _analyticsBox.put(_keyGoals, goals);
      
      await trackAppEvent('goals_updated', properties: {
        'daily_goal': goals['daily_goal'],
        'weekly_goal': goals['weekly_goal'],
        'monthly_goal': goals['monthly_goal'],
      });
    } catch (e) {
      debugPrint('❌ Error setting goals: $e');
    }
  }

  /// รับเป้าหมาย
  static Map<String, dynamic> getGoals() {
    try {
      return Map<String, dynamic>.from(_analyticsBox.get(_keyGoals) ?? {
        'daily_goal': 8,
        'weekly_goal': 40,
        'monthly_goal': 160,
      });
    } catch (e) {
      debugPrint('❌ Error getting goals: $e');
      return {
        'daily_goal': 8,
        'weekly_goal': 40,
        'monthly_goal': 160,
      };
    }
  }

  /// ตรวจสอบความก้าวหน้าเป้าหมาย
  static Map<String, dynamic> getGoalProgress() {
    try {
      final goals = getGoals();
      final today = DateTime.now();
      
      // Daily progress
      final todayStats = getDailyStats(today);
      final dailyCompleted = todayStats['completed_sessions'] ?? 0;
      final dailyGoal = goals['daily_goal'] ?? 8;
      final dailyProgress = math.min(100, (dailyCompleted / dailyGoal) * 100);
      
      // Weekly progress
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weeklyStats = getWeeklyStats(weekStart);
      final weeklyCompleted = weeklyStats['completed_sessions'] ?? 0;
      final weeklyGoal = goals['weekly_goal'] ?? 40;
      final weeklyProgress = math.min(100, (weeklyCompleted / weeklyGoal) * 100);
      
      // Monthly progress
      final monthStart = DateTime(today.year, today.month, 1);
      final monthlyStats = getMonthlyStats(monthStart);
      final monthlyCompleted = monthlyStats['completed_sessions'] ?? 0;
      final monthlyGoal = goals['monthly_goal'] ?? 160;
      final monthlyProgress = math.min(100, (monthlyCompleted / monthlyGoal) * 100);
      
      return {
        'daily': {
          'completed': dailyCompleted,
          'goal': dailyGoal,
          'progress': dailyProgress,
          'remaining': math.max(0, dailyGoal - dailyCompleted),
          'achieved': dailyCompleted >= dailyGoal,
        },
        'weekly': {
          'completed': weeklyCompleted,
          'goal': weeklyGoal,
          'progress': weeklyProgress,
          'remaining': math.max(0, weeklyGoal - weeklyCompleted),
          'achieved': weeklyCompleted >= weeklyGoal,
        },
        'monthly': {
          'completed': monthlyCompleted,
          'goal': monthlyGoal,
          'progress': monthlyProgress,
          'remaining': math.max(0, monthlyGoal - monthlyCompleted),
          'achieved': monthlyCompleted >= monthlyGoal,
        },
      };
    } catch (e) {
      debugPrint('❌ Error getting goal progress: $e');
      return {};
    }
  }

  // ========================================
  // 📈 TRENDS & ANALYSIS
  // ========================================

  /// วิเคราะห์แนวโน้มการใช้งาน
  static Map<String, dynamic> getUsageTrends() {
    try {
      final now = DateTime.now();
      final last7Days = <Map<String, dynamic>>[];
      final last30Days = <Map<String, dynamic>>[];
      
      // รวบรวมข้อมูล 7 วันล่าสุด
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStats = getDailyStats(date);
        dayStats['date'] = DateFormat('MM-dd').format(date);
        dayStats['day_name'] = DateFormat('EEE', 'th').format(date);
        last7Days.add(dayStats);
      }
      
      // รวบรวมข้อมูล 30 วันล่าสุด  
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStats = getDailyStats(date);
        dayStats['date'] = DateFormat('MM-dd').format(date);
        last30Days.add(dayStats);
      }
      
      // คำนวณค่าเฉลี่ย
      final avgCompletionLast7Days = last7Days.fold<double>(0, (sum, day) => 
          sum + (day['completed_sessions'] ?? 0)) / 7;
      final avgCompletionLast30Days = last30Days.fold<double>(0, (sum, day) => 
          sum + (day['completed_sessions'] ?? 0)) / 30;
      
      // แนวโน้ม
      final trendDirection = avgCompletionLast7Days > avgCompletionLast30Days ? 'up' : 
                           avgCompletionLast7Days < avgCompletionLast30Days ? 'down' : 'stable';
      
      // วันที่ดีที่สุดใน 7 วันล่าสุด
      final bestDay = last7Days.reduce((a, b) => 
          (a['completed_sessions'] ?? 0) > (b['completed_sessions'] ?? 0) ? a : b);
          
      // ช่วงเวลาที่ดีที่สุด
      final hourDistribution = <int, int>{};
      for (final day in last30Days) {
        final dayHours = Map<int, int>.from(day['hour_distribution'] ?? {});
        dayHours.forEach((hour, count) {
          hourDistribution[hour] = (hourDistribution[hour] ?? 0) + count;
        });
      }
      
      int bestHour = 9; // default
      if (hourDistribution.isNotEmpty) {
        final bestHourEntry = hourDistribution.entries.reduce((a, b) => a.value > b.value ? a : b);
        bestHour = bestHourEntry.key;
      }
      
      return {
        'last_7_days': last7Days,
        'last_30_days': last30Days,
        'avg_completion_7_days': avgCompletionLast7Days.toStringAsFixed(1),
        'avg_completion_30_days': avgCompletionLast30Days.toStringAsFixed(1),
        'trend_direction': trendDirection,
        'trend_percentage': ((avgCompletionLast7Days - avgCompletionLast30Days) / (avgCompletionLast30Days + 0.1) * 100).toStringAsFixed(1),
        'best_day_recent': bestDay,
        'best_hour': bestHour,
        'best_hour_name': _getHourName(bestHour),
        'consistency_score': _calculateConsistencyScore(last7Days),
      };
    } catch (e) {
      debugPrint('❌ Error getting usage trends: $e');
      return {};
    }
  }

  /// แปลงชั่วโมงเป็นชื่อ
  static String _getHourName(int hour) {
    if (hour < 6) return 'ดึก';
    if (hour < 12) return 'เช้า';
    if (hour < 17) return 'บ่าย';
    if (hour < 20) return 'เย็น';
    return 'ค่ำ';
  }

  /// คำนวณคะแนนความสม่ำเสมอ
  static double _calculateConsistencyScore(List<Map<String, dynamic>> days) {
    if (days.isEmpty) return 0;
    
    final completions = days.map((day) => day['completed_sessions'] ?? 0).toList();
    final mean = completions.fold(0, (sum, val) => sum + val) / completions.length;
    
    if (mean == 0) return 0;
    
    final variance = completions.fold(0.0, (sum, val) => sum + math.pow(val - mean, 2)) / completions.length;
    final standardDeviation = math.sqrt(variance);
    
    // คะแนนความสม่ำเสมอ = 100 - (ค่าเบี่ยงเบนมาตรฐาน / ค่าเฉลี่ย * 100)
    final consistencyScore = math.max(0, 100 - (standardDeviation / mean * 100));
    return consistencyScore;
  }

  // ========================================
  // 🏆 COMPREHENSIVE ANALYTICS
  // ========================================

  /// รับสถิติสำหรับ Dashboard
  static Map<String, dynamic> getDashboardStats() {
    try {
      final usageStats = getUsageStats();
      final streakData = getStreakData();
      final goalProgress = getGoalProgress();
      final trends = getUsageTrends();
      final badges = getBadges();
      
      return {
        'overview': {
          'total_sessions': usageStats['total_sessions'] ?? 0,
          'total_completed': usageStats['total_completed'] ?? 0,
          'total_exercise_time': usageStats['total_exercise_time'] ?? 0,
          'overall_completion_rate': usageStats['overall_completion_rate'] ?? 0.0,
          'days_since_first_use': usageStats['days_since_first_use'] ?? 0,
        },
        'streaks': streakData,
        'goals': goalProgress,
        'trends': {
          'direction': trends['trend_direction'],
          'percentage': trends['trend_percentage'],
          'best_hour': trends['best_hour_name'],
          'consistency_score': trends['consistency_score'],
        },
        'badges': {
          'total_earned': badges.length,
          'recent_badges': badges.take(3).toList(),
        },
        'today': getDailyStats(DateTime.now()),
      };
    } catch (e) {
      debugPrint('❌ Error getting dashboard stats: $e');
      return {};
    }
  }

  // ========================================
  // 🧹 DATA MANAGEMENT
  // ========================================

  /// ลบข้อมูลเก่า
  static Future<void> cleanOldData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      // ลบ daily stats เก่า
      final dailyStats = Map<String, dynamic>.from(_analyticsBox.get(_keyDailyStats) ?? {});
      dailyStats.removeWhere((dateKey, _) {
        try {
          final date = DateTime.parse(dateKey);
          return date.isBefore(cutoffDate);
        } catch (e) {
          return true; // ลบถ้า parse ไม่ได้
        }
      });
      await _analyticsBox.put(_keyDailyStats, dailyStats);
      
      // ลบ session history เก่า
      final history = List<Map<String, dynamic>>.from(_analyticsBox.get(_keySessionHistory) ?? []);
      history.removeWhere((session) {
        try {
          final date = DateTime.parse(session['timestamp']);
          return date.isBefore(cutoffDate);
        } catch (e) {
          return true;
        }
      });
      await _analyticsBox.put(_keySessionHistory, history);
      
      // ลบ app events เก่า
      final events = List<Map<String, dynamic>>.from(_analyticsBox.get(_keyAppEvents) ?? []);
      events.removeWhere((event) {
        try {
          final date = DateTime.parse(event['timestamp']);
          return date.isBefore(cutoffDate);
        } catch (e) {
          return true;
        }
      });
      await _analyticsBox.put(_keyAppEvents, events);
      
      debugPrint('✅ Old analytics data cleaned (older than $daysToKeep days)');
    } catch (e) {
      debugPrint('❌ Error cleaning old data: $e');
    }
  }

  /// Export ข้อมูลสถิติทั้งหมด
  static Map<String, dynamic> exportAllData() {
    try {
      return {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0',
          'app': 'Office Syndrome Helper',
        },
        'usage_stats': getUsageStats(),
        'pain_point_stats': getPainPointStats(),
        'session_history': getSessionHistory(limit: 1000),
        'app_events': getAppEvents(limit: 500),
        'daily_stats': _analyticsBox.get(_keyDailyStats) ?? {},
        'streak_data': getStreakData(),
        'badges': getBadges(),
        'goals': getGoals(),
        'trends': getUsageTrends(),
        'dashboard_stats': getDashboardStats(),
      };
    } catch (e) {
      debugPrint('❌ Error exporting analytics data: $e');
      return {};
    }
  }

  /// ลบข้อมูลทั้งหมด
  static Future<void> clearAllData() async {
    try {
      await _analyticsBox.clear();
      await _initializeDefaultStats();
      
      await trackAppEvent('analytics_data_cleared', properties: {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ All analytics data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing analytics data: $e');
    }
  }

  /// Import ข้อมูลจากไฟล์ backup
  static Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // ตรวจสอบรูปแบบข้อมูล
      if (!data.containsKey('export_info')) {
        debugPrint('❌ Invalid data format');
        return false;
      }
      
      // นำเข้าข้อมูลแต่ละประเภท
      if (data.containsKey('usage_stats')) {
        await _analyticsBox.put(_keyUsageStats, data['usage_stats']);
      }
      if (data.containsKey('daily_stats')) {
        await _analyticsBox.put(_keyDailyStats, data['daily_stats']);
      }
      if (data.containsKey('pain_point_stats')) {
        await _analyticsBox.put(_keyPainPointStats, data['pain_point_stats']);
      }
      if (data.containsKey('session_history')) {
        await _analyticsBox.put(_keySessionHistory, data['session_history']);
      }
      if (data.containsKey('streak_data')) {
        await _analyticsBox.put(_keyStreakData, data['streak_data']);
      }
      if (data.containsKey('badges')) {
        await _analyticsBox.put(_keyBadges, data['badges']);
      }
      if (data.containsKey('goals')) {
        await _analyticsBox.put(_keyGoals, data['goals']);
      }
      
      await trackAppEvent('analytics_data_imported', properties: {
        'timestamp': DateTime.now().toIso8601String(),
        'import_version': data['export_info']['version'],
      });
      
      debugPrint('✅ Analytics data imported successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error importing analytics data: $e');
      return false;
    }
  }

  /// รับสถิติสำหรับการ Debug
  static Map<String, dynamic> getDebugInfo() {
    try {
      return {
        'box_info': {
          'is_open': _analyticsBox.isOpen,
          'path': _analyticsBox.path,
          'length': _analyticsBox.length,
          'keys': _analyticsBox.keys.toList(),
        },
        'data_sizes': {
          'usage_stats': (_analyticsBox.get(_keyUsageStats) ?? {}).length,
          'daily_stats': (_analyticsBox.get(_keyDailyStats) ?? {}).length,
          'session_history': (_analyticsBox.get(_keySessionHistory) ?? []).length,
          'app_events': (_analyticsBox.get(_keyAppEvents) ?? []).length,
          'badges': (_analyticsBox.get(_keyBadges) ?? []).length,
        },
        'memory_usage': 'N/A', // จะต้องใช้ package เพิ่มเติม
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting debug info: $e');
      return {};
    }
  }
}