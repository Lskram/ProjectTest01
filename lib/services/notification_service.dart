import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_session.dart';
import '../models/user_settings.dart';
import 'database_service.dart';
import 'random_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;

  /// เริ่มต้น notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();

    // Initialize notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  /// เมื่อผู้ใช้กด notification
  void _onNotificationTap(NotificationResponse response) {
    final sessionId = response.payload;
    if (sessionId != null) {
      // Navigate to TodoPage with sessionId
      // เมื่อสร้าง routes แล้วจะใช้คำสั่งนี้:
      // Get.toNamed(AppRoutes.todo, arguments: sessionId);

      // สำหรับตอนนี้ให้ print debug
      debugPrint('🔔 Notification tapped: $sessionId');
    }
  }

  /// ตั้งการแจ้งเตือนครั้งต่อไป
  Future<void> scheduleNextNotification() async {
    final settings = DatabaseService.instance.getUserSettings();

    if (!settings.notificationsEnabled) return;
    if (!settings.hasSelectedPainPoints) return;

    final nextTime = _calculateNextNotificationTime(settings);
    if (nextTime == null) return;

    // สุ่มเลือก pain point และ treatments
    final randomData = RandomService.instance.selectRandomTreatments(
      settings.selectedPainPointIds,
    );

    if (randomData == null) return;

    // สร้าง NotificationSession
    final session = NotificationSession(
      id: _uuid.v4(),
      scheduledTime: nextTime,
      painPointId: randomData['painPoint'].id,
      treatmentIds: randomData['treatments'].map<int>((t) => t.id).toList(),
    );

    // บันทึกลง database
    await DatabaseService.instance.saveNotificationSession(session);

    // ตั้ง alarm
    await _scheduleNotification(session, randomData['painPoint'].name);
  }

  /// คำนวณเวลาแจ้งเตือนครั้งถัดไป
  DateTime? _calculateNextNotificationTime(UserSettings settings) {
    final now = DateTime.now();
    var nextTime = now.add(Duration(minutes: settings.intervalMinutes));

    // วนลูปหาเวลาที่เหมาะสม
    for (int attempts = 0; attempts < 10; attempts++) {
      // เช็คว่าเป็นวันทำงานหรือไม่
      if (!settings.workDays.contains(nextTime.weekday)) {
        nextTime = _findNextWorkDay(nextTime, settings.workDays);
        continue;
      }

      // เช็คว่าอยู่ในช่วงเวลาทำงานหรือไม่
      if (!_isInWorkingHours(nextTime, settings)) {
        nextTime = _adjustToWorkingHours(nextTime, settings);
        continue;
      }

      // เช็คว่าอยู่ในช่วงพักหรือไม่
      if (_isInBreakPeriod(nextTime, settings.breakPeriods)) {
        nextTime = _skipBreakPeriod(nextTime, settings.breakPeriods);
        continue;
      }

      // ถ้าผ่านทุกเงื่อนไข
      return nextTime;
    }

    return null; // ไม่พบเวลาที่เหมาะสม
  }

  /// หาวันทำงานถัดไป
  DateTime _findNextWorkDay(DateTime current, List<int> workDays) {
    var next = DateTime(current.year, current.month, current.day + 1, 9, 0);

    while (!workDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  /// เช็คว่าอยู่ในช่วงเวลาทำงานหรือไม่
  bool _isInWorkingHours(DateTime time, UserSettings settings) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes =
        settings.workStartTime.hour * 60 + settings.workStartTime.minute;
    final endMinutes =
        settings.workEndTime.hour * 60 + settings.workEndTime.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// ปรับเวลาให้อยู่ในช่วงทำงาน
  DateTime _adjustToWorkingHours(DateTime time, UserSettings settings) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes =
        settings.workStartTime.hour * 60 + settings.workStartTime.minute;

    if (timeMinutes < startMinutes) {
      // ก่อนเวลาทำงาน -> ย้ายไปเวลาเริ่มทำงาน
      return DateTime(
        time.year,
        time.month,
        time.day,
        settings.workStartTime.hour,
        settings.workStartTime.minute,
      );
    } else {
      // หลังเวลาทำงาน -> ย้ายไปวันถัดไป
      return _findNextWorkDay(
          time, DatabaseService.instance.getUserSettings().workDays);
    }
  }

  /// เช็คว่าอยู่ในช่วงพักหรือไม่
  bool _isInBreakPeriod(DateTime time, List<BreakPeriod> breakPeriods) {
    for (final breakPeriod in breakPeriods) {
      if (breakPeriod.isActive && breakPeriod.isCurrentlyInBreak()) {
        return true;
      }
    }
    return false;
  }

  /// ข้ามช่วงเวลาพัก
  DateTime _skipBreakPeriod(DateTime time, List<BreakPeriod> breakPeriods) {
    for (final breakPeriod in breakPeriods) {
      if (breakPeriod.isActive && breakPeriod.isCurrentlyInBreak()) {
        // ย้ายไปหลังช่วงพัก
        return DateTime(
          time.year,
          time.month,
          time.day,
          breakPeriod.endTime.hour,
          breakPeriod.endTime.minute,
        ).add(const Duration(minutes: 5)); // เผื่อ 5 นาที
      }
    }
    return time;
  }

  /// ตั้ง notification จริง
  Future<void> _scheduleNotification(
      NotificationSession session, String painPointName) async {
    const androidDetails = AndroidNotificationDetails(
      'office_syndrome_channel',
      'Office Syndrome Notifications',
      channelDescription: 'Notifications for exercise reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
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
      session.id.hashCode, // Use hashCode as int ID
      '⏰ ถึงเวลาดูแล: $painPointName',
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

    // ยกเลิก notification เดิม
    await cancelNotification(sessionId);

    // สร้าง session ใหม่ที่เลื่อนไป
    final snoozedSession = session.snooze(minutes);
    await DatabaseService.instance.saveNotificationSession(snoozedSession);

    // ตั้ง notification ใหม่
    final painPoint = DatabaseService.instance
        .getAllPainPoints()
        .firstWhere((p) => p.id == session.painPointId);

    await _scheduleNotification(snoozedSession, painPoint.name);
    debugPrint('😴 Notification snoozed for $minutes minutes');
  }

  /// ข้ามการแจ้งเตือน
  Future<void> skipNotification(String sessionId) async {
    final session = DatabaseService.instance.getNotificationSession(sessionId);
    if (session == null) return;

    // ยกเลิก notification
    await cancelNotification(sessionId);

    // อัปเดตสถานะเป็น skipped
    final skippedSession = session.skip();
    await DatabaseService.instance.saveNotificationSession(skippedSession);

    // ตั้งการแจ้งเตือนครั้งถัดไป
    await scheduleNextNotification();
    debugPrint('⏭️ Notification skipped');
  }

  /// เสร็จสิ้นการออกกำลังกาย
  Future<void> completeNotification(String sessionId) async {
    final session = DatabaseService.instance.getNotificationSession(sessionId);
    if (session == null) return;

    // ยกเลิก notification
    await cancelNotification(sessionId);

    // อัปเดตสถานะเป็น completed
    final completedSession = session.markAsCompleted();
    await DatabaseService.instance.saveNotificationSession(completedSession);

    // ตั้งการแจ้งเตือนครั้งถัดไป
    await scheduleNextNotification();
    debugPrint('✅ Notification completed');
  }
}
