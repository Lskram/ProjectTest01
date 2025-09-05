import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'dart:ui';
import '../models/notification_session.dart';
import '../models/user_settings.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import 'database_service.dart';
import 'random_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  static const String _portName = 'notification_service_port';
  static const int _alarmId = 0;

  FlutterLocalNotificationsPlugin? _localNotifications;
  final Uuid _uuid = const Uuid();

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize alarm manager
      await AndroidAlarmManager.initialize();

      // Register isolate callback
      IsolateNameServer.registerPortWithName(
        _createIsolateReceivePort().sendPort,
        _portName,
      );

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
  }

  /// Create notification channels
  Future<void> _createNotificationChannels() async {
    if (_localNotifications == null) return;

    // Exercise reminder channel
    const exerciseChannel = AndroidNotificationChannel(
      'exercise_reminders',
      'การแจ้งเตือนออกกำลังกาย',
      description: 'แจ้งเตือนให้ออกกำลังกายตามเวลาที่กำหนด',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    // Persistent notification channel
    const persistentChannel = AndroidNotificationChannel(
      'persistent_status',
      'สถานะการทำงาน',
      description: 'แสดงสถานะการทำงานของระบบแจ้งเตือน',
      importance: Importance.low,
      priority: Priority.low,
      enableVibration: false,
      playSound: false,
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(exerciseChannel);

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('🔔 Notification tapped: ${response.payload}');

      if (response.payload != null) {
        // Navigate to todo page with session ID
        // This will be handled by the main app
        final port = IsolateNameServer.lookupPortByName('main_isolate_port');
        port?.send({
          'type': 'notification_tapped',
          'sessionId': response.payload,
        });
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Start notification scheduling
  Future<bool> startScheduling() async {
    try {
      final settings = await DatabaseService.instance.loadSettings();

      if (!settings.isNotificationEnabled) {
        debugPrint('🔔 Notifications are disabled');
        return false;
      }

      // Calculate next notification time using FIXED INTERVAL LOGIC
      final nextTime = _calculateNextNotificationTime(settings);

      if (nextTime == null) {
        debugPrint('🔔 Cannot calculate next notification time');
        return false;
      }

      debugPrint('🔔 Next notification scheduled for: $nextTime');

      // Schedule the alarm
      final success = await AndroidAlarmManager.oneShotAt(
        nextTime,
        _alarmId,
        _backgroundNotificationCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      if (success) {
        debugPrint('✅ Notification scheduled successfully');
        await _showPersistentStatusNotification(nextTime);
      } else {
        debugPrint('❌ Failed to schedule notification');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error starting notification scheduling: $e');
      return false;
    }
  }

  /// Calculate next notification time with FIXED INTERVAL LOGIC
  DateTime? _calculateNextNotificationTime(UserSettings settings) {
    try {
      final now = DateTime.now();
      DateTime candidateTime;

      if (settings.lastNotificationTime == null) {
        // First time - start from now + interval
        candidateTime =
            now.add(Duration(minutes: settings.notificationInterval));
        debugPrint('🕐 First notification: ${candidateTime}');
      } else {
        // FIXED INTERVAL: lastNotificationTime + interval
        candidateTime = settings.lastNotificationTime!
            .add(Duration(minutes: settings.notificationInterval));
        debugPrint('🕐 Fixed interval calculation: ${candidateTime}');

        // If calculated time is in the past, move to next valid slot
        while (candidateTime.isBefore(now)) {
          candidateTime = candidateTime
              .add(Duration(minutes: settings.notificationInterval));
          debugPrint('🕐 Adjusted to future: ${candidateTime}');
        }
      }

      // Find next valid time within working hours
      DateTime? nextValidTime = _findNextValidTime(candidateTime, settings);

      if (nextValidTime != null) {
        debugPrint('✅ Next valid time found: ${nextValidTime}');
        return nextValidTime;
      }

      debugPrint('❌ No valid time found');
      return null;
    } catch (e) {
      debugPrint('❌ Error calculating next notification time: $e');
      return null;
    }
  }

  /// Find next valid time considering working hours and break times
  DateTime? _findNextValidTime(DateTime startTime, UserSettings settings) {
    DateTime candidate = startTime;

    // Search for next 7 days to find valid time
    for (int day = 0; day < 7; day++) {
      final dayCandidate = candidate.add(Duration(days: day));

      // Check if it's a working day
      if (!settings.isWorkingDay(dayCandidate.weekday)) {
        continue;
      }

      // Check if within working hours
      if (settings.isWithinWorkingHours(dayCandidate)) {
        // Check if not in break time
        if (!settings.isInBreakTime(dayCandidate)) {
          return dayCandidate;
        }
      }

      // If not in working hours, try start of next working day
      if (day == 0) {
        final tomorrow = DateTime(
          dayCandidate.year,
          dayCandidate.month,
          dayCandidate.day + 1,
        );
        final workStart = settings.workStart;
        candidate = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          workStart.hour,
          workStart.minute,
        );
      }
    }

    return null;
  }

  /// Background callback for alarm manager
  @pragma('vm:entry-point')
  static Future<void> _backgroundNotificationCallback() async {
    try {
      debugPrint('🔔 Background notification callback triggered');

      // Initialize database in isolate
      await DatabaseService.instance.initializeInIsolate();

      final settings = await DatabaseService.instance.loadSettings();

      // Check if should notify now
      final now = DateTime.now();
      if (!settings.shouldNotifyNow(now)) {
        debugPrint('🔔 Should not notify now, rescheduling...');
        await NotificationService.instance._rescheduleNext();
        return;
      }

      // Create notification session
      final sessionId = const Uuid().v4();
      final session =
          await NotificationService.instance._createNotificationSession(
        sessionId,
        settings,
      );

      if (session != null) {
        // Show notification
        await NotificationService.instance._showExerciseNotification(session);

        // Update lastNotificationTime
        final updatedSettings = settings.copyWith(
          lastNotificationTime: now,
          currentSessionId: sessionId,
        );
        await DatabaseService.instance.saveSettings(updatedSettings);

        debugPrint('✅ Notification shown successfully');
      }

      // Schedule next notification
      await NotificationService.instance._rescheduleNext();
    } catch (e) {
      debugPrint('❌ Error in background notification callback: $e');
    }
  }

  /// Create notification session
  Future<NotificationSession?> _createNotificationSession(
    String sessionId,
    UserSettings settings,
  ) async {
    try {
      // Get random pain point and treatments
      final randomData = await RandomService.instance.getRandomTreatments(
        settings.selectedPainPointIds,
      );

      if (randomData == null) {
        debugPrint('❌ No random treatments available');
        return null;
      }

      final session = NotificationSession(
        id: sessionId,
        scheduledTime: DateTime.now(),
        painPointId: randomData['painPoint'].id,
        treatmentIds: randomData['treatments'].map<int>((t) => t.id).toList(),
        status: SessionStatusHive.pending,
      );

      // Save session to database
      await DatabaseService.instance.saveNotificationSession(session);

      debugPrint('✅ Created notification session: $sessionId');
      return session;
    } catch (e) {
      debugPrint('❌ Error creating notification session: $e');
      return null;
    }
  }

  /// Show exercise notification
  Future<void> _showExerciseNotification(NotificationSession session) async {
    try {
      if (_localNotifications == null) {
        await _initializeLocalNotifications();
      }

      final painPoint =
          await DatabaseService.instance.getPainPointById(session.painPointId);
      final treatments = await DatabaseService.instance
          .getTreatmentsByIds(session.treatmentIds);

      if (painPoint == null || treatments.isEmpty) {
        debugPrint(
            '❌ Cannot show notification: missing pain point or treatments');
        return;
      }

      final title = '🏃‍♂️ เวลาออกกำลังกาย!';
      final body =
          'มาทำท่า${painPoint.nameTh}กันเถอะ (${treatments.length} ท่า)';

      const androidDetails = AndroidNotificationDetails(
        'exercise_reminders',
        'การแจ้งเตือนออกกำลังกาย',
        channelDescription: 'แจ้งเตือนให้ออกกำลังกายตามเวลาที่กำหนด',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        actions: [
          AndroidNotificationAction(
            'start_exercise',
            'เริ่มออกกำลังกาย',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_play'),
          ),
          AndroidNotificationAction(
            'snooze',
            'เลื่อน 5 นาที',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
          ),
          AndroidNotificationAction(
            'skip',
            'ข้าม',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_skip'),
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        session.hashCode,
        title,
        body,
        notificationDetails,
        payload: session.id,
      );

      debugPrint('✅ Exercise notification shown');
    } catch (e) {
      debugPrint('❌ Error showing exercise notification: $e');
    }
  }

  /// Show persistent status notification
  Future<void> _showPersistentStatusNotification(DateTime nextTime) async {
    try {
      if (_localNotifications == null) return;

      final timeText =
          '${nextTime.hour.toString().padLeft(2, '0')}:${nextTime.minute.toString().padLeft(2, '0')}';

      const androidDetails = AndroidNotificationDetails(
        'persistent_status',
        'สถานะการทำงาน',
        channelDescription: 'แสดงสถานะการทำงานของระบบแจ้งเตือน',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        enableVibration: false,
        playSound: false,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications!.show(
        999999, // Fixed ID for persistent notification
        '⏰ Office Syndrome Helper ทำงานอยู่',
        'แจ้งเตือนครั้งถัดไป: วันนี้ $timeText',
        notificationDetails,
      );
    } catch (e) {
      debugPrint('❌ Error showing persistent notification: $e');
    }
  }

  /// Reschedule next notification
  Future<void> _rescheduleNext() async {
    try {
      // Cancel current alarm
      await AndroidAlarmManager.cancel(_alarmId);

      // Start scheduling again
      await startScheduling();
    } catch (e) {
      debugPrint('❌ Error rescheduling: $e');
    }
  }

  /// Stop all notifications
  Future<void> stopScheduling() async {
    try {
      await AndroidAlarmManager.cancel(_alarmId);
      await _localNotifications?.cancelAll();
      debugPrint('✅ All notifications stopped');
    } catch (e) {
      debugPrint('❌ Error stopping notifications: $e');
    }
  }

  /// Test notification (for development)
  Future<void> testNotification() async {
    try {
      debugPrint('🧪 Testing notification...');

      final sessionId = _uuid.v4();
      final settings = await DatabaseService.instance.loadSettings();

      final session = await _createNotificationSession(sessionId, settings);
      if (session != null) {
        await _showExerciseNotification(session);
        debugPrint('✅ Test notification sent');
      }
    } catch (e) {
      debugPrint('❌ Error testing notification: $e');
    }
  }

  /// Create isolate receive port
  ReceivePort _createIsolateReceivePort() {
    final port = ReceivePort();
    port.listen((data) {
      debugPrint('📩 Received isolate message: $data');
      // Handle isolate messages here
    });
    return port;
  }

  /// Handle notification actions (snooze, skip)
  Future<void> handleNotificationAction(String action, String sessionId) async {
    try {
      final session =
          await DatabaseService.instance.getNotificationSession(sessionId);
      if (session == null) return;

      switch (action) {
        case 'snooze':
          await _handleSnooze(session);
          break;
        case 'skip':
          await _handleSkip(session);
          break;
        case 'start_exercise':
          await _handleStartExercise(session);
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling notification action: $e');
    }
  }

  Future<void> _handleSnooze(NotificationSession session) async {
    final settings = await DatabaseService.instance.loadSettings();
    final snoozeTime =
        DateTime.now().add(Duration(minutes: settings.snoozeInterval));

    // Update session
    final updatedSession = session.copyWith(
      status: SessionStatusHive.snoozed,
      snoozeCount: session.snoozeCount + 1,
      snoozeTimes: [...session.snoozeTimes ?? [], DateTime.now()],
    );
    await DatabaseService.instance.saveNotificationSession(updatedSession);

    // Schedule snooze notification
    await AndroidAlarmManager.oneShotAt(
      snoozeTime,
      sessionId.hashCode,
      _backgroundNotificationCallback,
      exact: true,
    );
  }

  Future<void> _handleSkip(NotificationSession session) async {
    final updatedSession = session.copyWith(
      status: SessionStatusHive.skipped,
      completedTime: DateTime.now(),
    );
    await DatabaseService.instance.saveNotificationSession(updatedSession);

    // Update lastNotificationTime to maintain interval
    final settings = await DatabaseService.instance.loadSettings();
    final updatedSettings = settings.copyWith(
      lastNotificationTime: DateTime.now(),
      currentSessionId: null,
    );
    await DatabaseService.instance.saveSettings(updatedSettings);
  }

  Future<void> _handleStartExercise(NotificationSession session) async {
    final updatedSession = session.copyWith(
      status: SessionStatusHive.inProgress,
      actualStartTime: DateTime.now(),
    );
    await DatabaseService.instance.saveNotificationSession(updatedSession);
  }
}
