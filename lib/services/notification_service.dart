import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/random_service.dart';
import '../models/notification_session.dart';
import '../models/user_settings.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  late FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _notifications = FlutterLocalNotificationsPlugin();

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload != 'test_notification') {
      // Navigate to exercise page with session ID
      debugPrint('📱 Notification tapped: $payload');
      // Get.toNamed('/todo', arguments: payload);
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'office_syndrome_channel',
      'Office Syndrome Notifications',
      description: 'Notifications for exercise reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// ตั้งเวลาแจ้งเตือนถัดไปแบบ Fixed Interval
  Future<void> scheduleNextNotification() async {
    try {
      final settings = DatabaseService.instance.getUserSettings();
      
      if (!settings.notificationsEnabled) {
        debugPrint('📴 Notifications disabled');
        return;
      }

      // ยกเลิกการแจ้งเตือนเก่าทั้งหมดก่อน
      await cancelAllNotifications();

      // คำนวณเวลาถัดไปแบบ Fixed Interval
      final nextTime = _calculateNextNotificationTime(settings);
      
      if (nextTime == null) {
        debugPrint('⏰ No valid next notification time');
        return;
      }

      // สร้าง session ใหม่
      final session = await _createNotificationSession(nextTime);
      
      // ตั้งการแจ้งเตือน
      await _scheduleNotification(session);

      // บันทึก lastNotificationTime ใหม่
      await _updateLastNotificationTime(nextTime);

      debugPrint('🔔 Next notification scheduled for: $nextTime');
    } catch (e) {
      debugPrint('❌ Schedule notification error: $e');
    }
  }

  /// คำนวณเวลาแจ้งเตือนถัดไปแบบ Fixed Interval
  DateTime? _calculateNextNotificationTime(UserSettings settings) {
    final now = DateTime.now();
    
    // ถ้าไม่มี lastNotificationTime ให้เริ่มจากตอนนี้
    DateTime baseTime = settings.lastNotificationTime ?? now;
    
    // ถ้า lastNotificationTime เป็นอนาคต (ผิดปกติ) ให้ใช้เวลาปัจจุบัน
    if (baseTime.isAfter(now)) {
      baseTime = now;
    }

    // คำนวณเวลาถัดไปจาก baseTime + interval
    DateTime nextTime = baseTime.add(Duration(minutes: settings.intervalMinutes));
    
    // ถ้าเวลาถัดไปผ่านมาแล้ว ให้คำนวณใหม่จากตอนนี้
    while (nextTime.isBefore(now)) {
      nextTime = nextTime.add(Duration(minutes: settings.intervalMinutes));
    }

    // เช็คว่าอยู่ในช่วงเวลาทำงานหรือไม่
    if (!_isValidNotificationTime(nextTime, settings)) {
      // ถ้าไม่ใช่ ให้หาเวลาทำงานถัดไป
      nextTime = _findNextWorkingTime(nextTime, settings);
    }

    return nextTime;
  }

  /// เช็คว่าเวลาดังกล่าวเหมาะสำหรับแจ้งเตือนหรือไม่
  bool _isValidNotificationTime(DateTime time, UserSettings settings) {
    // เช็ควันทำงาน
    final weekday = time.weekday;
    if (!settings.workDays.contains(weekday)) {
      return false;
    }

    // เช็คเวลาทำงาน
    final timeOfDay = TimeOfDay.fromDateTime(time);
    final currentMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
    final startMinutes = settings.workStartTime.hour * 60 + settings.workStartTime.minute;
    final endMinutes = settings.workEndTime.hour * 60 + settings.workEndTime.minute;
    
    if (currentMinutes < startMinutes || currentMinutes > endMinutes) {
      return false;
    }

    // เช็คช่วงพัก
    for (final breakPeriod in settings.breakPeriods) {
      final breakStartMinutes = breakPeriod.startTime.hour * 60 + breakPeriod.startTime.minute;
      final breakEndMinutes = breakPeriod.endTime.hour * 60 + breakPeriod.endTime.minute;
      
      if (currentMinutes >= breakStartMinutes && currentMinutes <= breakEndMinutes) {
        return false;
      }
    }

    return true;
  }

  /// หาเวลาทำงานถัดไป
  DateTime _findNextWorkingTime(DateTime startTime, UserSettings settings) {
    DateTime candidateTime = startTime;
    
    // หาสูงสุด 7 วัน
    for (int day = 0; day < 7; day++) {
      final checkDate = candidateTime.add(Duration(days: day));
      final weekday = checkDate.weekday;
      
      if (settings.workDays.contains(weekday)) {
        // วันนี้เป็นวันทำงาน ตั้งเวลาเป็นเวลาเริ่มงาน
        final workStartTime = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          settings.workStartTime.hour,
          settings.workStartTime.minute,
        );
        
        // ถ้าเป็นวันเดียวกันและยังไม่ถึงเวลาเริ่มงาน
        if (day == 0 && workStartTime.isAfter(DateTime.now())) {
          return workStartTime;
        }
        // ถ้าเป็นวันอื่น
        else if (day > 0) {
          return workStartTime;
        }
      }
    }
    
    // fallback: วันจันทร์หน้า 9:00
    final nextMonday = candidateTime.add(Duration(days: (8 - candidateTime.weekday) % 7));
    return DateTime(
      nextMonday.year,
      nextMonday.month,
      nextMonday.day,
      9,
      0,
    );
  }

  /// สร้าง NotificationSession ใหม่
  Future<NotificationSession> _createNotificationSession(DateTime scheduledTime) async {
    final session = await RandomService.instance.createRandomSession(scheduledTime);
    await DatabaseService.instance.saveNotificationSession(session);
    return session;
  }

  /// บันทึก lastNotificationTime ใหม่
  Future<void> _updateLastNotificationTime(DateTime time) async {
    try {
      final currentSettings = DatabaseService.instance.getUserSettings();
      final updatedSettings = currentSettings.copyWith(
        lastNotificationTime: time,
      );
      await DatabaseService.instance.saveUserSettings(updatedSettings);
      debugPrint('✅ Updated lastNotificationTime: $time');
    } catch (e) {
      debugPrint('❌ Error updating lastNotificationTime: $e');
    }
  }

  /// ตั้งการแจ้งเตือนใน system
  Future<void> _scheduleNotification(NotificationSession session) async {
    final painPoint = DatabaseService.instance
        .getAllPainPoints()
        .where((p) => p.id == session.painPointId)
        .firstOrNull;

    if (painPoint == null) {
      debugPrint('❌ PainPoint not found for session');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'office_syndrome_channel',
      'Office Syndrome Notifications',
      channelDescription: 'Notifications for exercise reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      session.id.hashCode,
      '⏰ ถึงเวลาดูแล: ${painPoint.name}',
      'กดเพื่อเริ่มออกกำลังกาย 💪',
      tz.TZDateTime.from(session.scheduledTime, tz.local),
      details,
      payload: session.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('🔔 Notification scheduled for: ${session.scheduledTime}');
  }

  /// ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🔕 All notifications cancelled');
  }

  /// ยกเลิกการแจ้งเตือนเฉพาะ
  Future<void> cancelNotification(String sessionId) async {
    await _notifications.cancel(sessionId.hashCode);
    debugPrint('🔕 Notification cancelled: $sessionId');
  }

  /// เลื่อนการแจ้งเตือน
  Future<void> snoozeNotification(String sessionId, int minutes) async {
    final session = DatabaseService.instance.getNotificationSession(sessionId);
    if (session == null) return;

    // ยกเลิก notification เก่า
    await cancelNotification(sessionId);

    // สร้างเวลาใหม่
    final newTime = DateTime.now().add(Duration(minutes: minutes));

    // อัพเดท session
    final snoozedSession = session.copyWith(
      scheduledTime: newTime,
      status: SessionStatus.snoozed,
      snoozeCount: session.snoozeCount + 1,
      snoozeTimes: [...session.snoozeTimes, DateTime.now()],
    );

    await DatabaseService.instance.saveNotificationSession(snoozedSession);

    // ตั้งการแจ้งเตือนใหม่
    await _scheduleNotification(snoozedSession);

    debugPrint('😴 Notification snoozed for $minutes minutes');
  }

  /// ข้ามการแจ้งเตือน
  Future<void> skipNotification(String sessionId) async {
    final session = DatabaseService.instance.getNotificationSession(sessionId);
    if (session == null) return;

    // ยกเลิก notification
    await cancelNotification(sessionId);

    // อัพเดท session เป็น skipped
    final skippedSession = session.copyWith(
      status: SessionStatus.skipped,
    );

    await DatabaseService.instance.saveNotificationSession(skippedSession);

    // ตั้งการแจ้งเตือนถัดไป
    await scheduleNextNotification();

    debugPrint('⏭️ Notification skipped');
  }

  /// ทำออกกำลังกายเสร็จ
  Future<void> completeNotification(String sessionId) async {
    final session = DatabaseService.instance.getNotificationSession(sessionId);
    if (session == null) return;

    // ยกเลิก notification
    await cancelNotification(sessionId);

    // อัพเดท session เป็น completed
    final completedSession = session.copyWith(
      status: SessionStatus.completed,
      completedTime: DateTime.now(),
    );

    await DatabaseService.instance.saveNotificationSession(completedSession);

    // ตั้งการแจ้งเตือนถัดไป
    await scheduleNextNotification();

    debugPrint('🎉 Notification completed');
  }

  /// ดูการแจ้งเตือนที่รออยู่
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Debug: แสดงการแจ้งเตือนที่รออยู่
  Future<void> debugPendingNotifications() async {
    if (!kDebugMode) return;

    final pending = await getPendingNotifications();
    debugPrint('=== Pending Notifications ===');
    debugPrint('Count: ${pending.length}');
    for (final notification in pending) {
      debugPrint('ID: ${notification.id}, Title: ${notification.title}');
    }
    debugPrint('============================');
  }
}