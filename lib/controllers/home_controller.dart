import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_settings.dart';
import '../models/notification_session.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import 'app_controller.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find();

  // Reactive variables
  final _isLoading = false.obs;
  final _settings = Rxn<UserSettings>();
  final _currentSession = Rxn<NotificationSession>();
  final _nextNotificationTime = Rxn<DateTime>();
  final _timeRemaining = ''.obs;
  final _progress = 0.0.obs;
  final _permissionStatus = false.obs;
  final _todayStats = Rxn<Map<String, dynamic>>();

  // Timer for real-time updates
  Timer? _updateTimer;

  // Getters
  bool get isLoading => _isLoading.value;
  UserSettings? get settings => _settings.value;
  NotificationSession? get currentSession => _currentSession.value;
  DateTime? get nextNotificationTime => _nextNotificationTime.value;
  String get timeRemaining => _timeRemaining.value;
  double get progress => _progress.value;
  bool get hasPermissions => _permissionStatus.value;
  Map<String, dynamic>? get todayStats => _todayStats.value;

  // Computed properties
  bool get isNotificationEnabled => settings?.isNotificationEnabled ?? false;
  bool get hasActiveSession => currentSession != null;
  String get statusText {
    if (!hasPermissions) return 'ต้องการอนุญาติเพื่อใช้งาน';
    if (!isNotificationEnabled) return 'การแจ้งเตือนถูกปิด';
    if (hasActiveSession) return 'มีกิจกรรมรอดำเนินการ';
    if (nextNotificationTime != null) return 'รอการแจ้งเตือนถัดไป';
    return 'ไม่มีการแจ้งเตือนที่กำหนดไว้';
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('🏠 HomeController initialized');
    _initialize();
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    super.onClose();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    try {
      _isLoading.value = true;

      await _loadData();
      await _checkPermissions();
      await _loadTodayStats();

      // Start real-time updates (every 1 second)
      _startRealTimeUpdates();
    } catch (e) {
      debugPrint('❌ Error initializing HomeController: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load essential data
  Future<void> _loadData() async {
    try {
      // Load settings
      final settings = await DatabaseService.instance.loadSettings();
      _settings.value = settings;

      // Calculate next notification time
      if (settings.isNotificationEnabled) {
        final nextTime = settings.calculateNextNotificationTime();
        _nextNotificationTime.value = nextTime;
      }

      // Load current session if exists
      if (settings.currentSessionId != null) {
        final session = await DatabaseService.instance
            .getNotificationSession(settings.currentSessionId!);
        _currentSession.value = session;
      }

      debugPrint('🏠 Data loaded successfully');
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    }
  }

  /// Check permissions status
  Future<void> _checkPermissions() async {
    try {
      final hasPerms =
          await PermissionService.instance.areAllCriticalPermissionsGranted();
      _permissionStatus.value = hasPerms;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }
  }

  /// Load today's statistics
  Future<void> _loadTodayStats() async {
    try {
      final stats = await DatabaseService.instance.getStatistics(days: 1);
      _todayStats.value = stats;
    } catch (e) {
      debugPrint('❌ Error loading today stats: $e');
    }
  }

  /// Start real-time updates (every 1 second)
  void _startRealTimeUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
      _updateProgress();
    });

    debugPrint('⏱️ Real-time updates started');
  }

  /// Update time remaining display
  void _updateTimeRemaining() {
    if (nextNotificationTime == null) {
      _timeRemaining.value = '';
      return;
    }

    final now = DateTime.now();
    final remaining = nextNotificationTime!.difference(now);

    if (remaining.isNegative) {
      _timeRemaining.value = 'ควรแจ้งเตือนแล้ว';
      _checkForMissedNotification();
      return;
    }

    // Format remaining time
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      _timeRemaining.value =
          '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      _timeRemaining.value = '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      _timeRemaining.value = '${seconds} วินาที';
    }
  }

  /// Update progress indicator
  void _updateProgress() {
    if (settings == null || nextNotificationTime == null) {
      _progress.value = 0.0;
      return;
    }

    final now = DateTime.now();
    final interval = Duration(minutes: settings!.notificationInterval);

    // Calculate progress based on last notification time
    final lastTime = settings!.lastNotificationTime ?? now.subtract(interval);
    final totalDuration = interval.inSeconds.toDouble();
    final elapsed = now.difference(lastTime).inSeconds.toDouble();

    final progressValue = (elapsed / totalDuration).clamp(0.0, 1.0);
    _progress.value = progressValue;
  }

  /// Check for missed notification
  void _checkForMissedNotification() async {
    if (nextNotificationTime == null) return;

    final now = DateTime.now();
    final missedBy = now.difference(nextNotificationTime!);

    if (missedBy.inMinutes > 5) {
      debugPrint('⚠️ Missed notification by ${missedBy.inMinutes} minutes');
      await _rescheduleNotifications();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    try {
      debugPrint('🔄 Refreshing home data...');

      await _loadData();
      await _checkPermissions();
      await _loadTodayStats();

      debugPrint('✅ Home data refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถรีเฟรชข้อมูลได้');
    }
  }

  /// Toggle notification enabled/disabled
  Future<void> toggleNotifications() async {
    try {
      if (settings == null) return;

      final newSettings = settings!.copyWith(
        isNotificationEnabled: !settings!.isNotificationEnabled,
      );

      await DatabaseService.instance.saveSettings(newSettings);
      _settings.value = newSettings;

      if (newSettings.isNotificationEnabled) {
        // Check permissions first
        final hasPerms = await PermissionService.instance.requestPermissions();
        if (hasPerms) {
          await NotificationService.instance.startScheduling();
          await _loadData(); // Reload to get new next notification time
        } else {
          // Revert if no permissions
          final revertSettings =
              newSettings.copyWith(isNotificationEnabled: false);
          await DatabaseService.instance.saveSettings(revertSettings);
          _settings.value = revertSettings;
        }
      } else {
        await NotificationService.instance.stopScheduling();
        _nextNotificationTime.value = null;
      }

      debugPrint(
          '🔔 Notifications toggled: ${newSettings.isNotificationEnabled}');
    } catch (e) {
      debugPrint('❌ Error toggling notifications: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถเปลี่ยนการตั้งค่าได้');
    }
  }

  /// Request permissions
  Future<void> requestPermissions() async {
    try {
      debugPrint('🔐 Requesting permissions...');

      final granted = await PermissionService.instance.requestPermissions();
      _permissionStatus.value = granted;

      if (granted) {
        Get.snackbar('สำเร็จ', 'ได้รับอนุญาติแล้ว');

        // Start notifications if enabled
        if (isNotificationEnabled) {
          await NotificationService.instance.startScheduling();
          await _loadData();
        }
      } else {
        Get.snackbar('ไม่สามารถดำเนินการได้', 'ต้องการอนุญาติเพื่อใช้งาน');
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
    }
  }

  /// Reschedule notifications
  Future<void> _rescheduleNotifications() async {
    try {
      await NotificationService.instance.stopScheduling();
      await Future.delayed(const Duration(seconds: 1));
      await NotificationService.instance.startScheduling();
      await _loadData();

      debugPrint('🔄 Notifications rescheduled');
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications: $e');
    }
  }

  /// Start exercise session
  Future<void> startExerciseSession() async {
    try {
      if (currentSession == null) {
        debugPrint('⚠️ No current session to start');
        return;
      }

      // Navigate to todo page
      Get.toNamed('/todo', arguments: currentSession!.id);
    } catch (e) {
      debugPrint('❌ Error starting exercise session: $e');
    }
  }

  /// Skip current session
  Future<void> skipCurrentSession() async {
    try {
      if (currentSession == null) return;

      final updatedSession = currentSession!.copyWith(
        status: SessionStatusHive.skipped,
        completedTime: DateTime.now(),
      );

      await DatabaseService.instance.saveNotificationSession(updatedSession);

      // Update lastNotificationTime to maintain interval
      final updatedSettings = settings!.copyWith(
        lastNotificationTime: DateTime.now(),
        currentSessionId: null,
      );
      await DatabaseService.instance.saveSettings(updatedSettings);

      // Refresh data
      await _loadData();
      await _loadTodayStats();

      Get.snackbar('ข้าม', 'ข้ามกิจกรรมแล้ว');
    } catch (e) {
      debugPrint('❌ Error skipping session: $e');
    }
  }

  /// Get session details for display
  Future<Map<String, dynamic>?> getCurrentSessionDetails() async {
    try {
      if (currentSession == null) return null;

      final painPoint = await DatabaseService.instance
          .getPainPointById(currentSession!.painPointId);
      final treatments = await DatabaseService.instance
          .getTreatmentsByIds(currentSession!.treatmentIds);

      return {
        'painPoint': painPoint,
        'treatments': treatments,
        'session': currentSession,
      };
    } catch (e) {
      debugPrint('❌ Error getting session details: $e');
      return null;
    }
  }

  /// Get formatted stats for display
  Map<String, String> get formattedTodayStats {
    if (todayStats == null) {
      return {
        'total': '0',
        'completed': '0',
        'rate': '0%',
      };
    }

    final total = todayStats!['totalSessions'] ?? 0;
    final completed = todayStats!['completedSessions'] ?? 0;
    final rate = todayStats!['completionRate'] ?? 0.0;

    return {
      'total': total.toString(),
      'completed': completed.toString(),
      'rate': '${(rate * 100).toInt()}%',
    };
  }

  /// Manual sync with app controller
  void syncWithAppController() {
    final appController = AppController.instance;
    if (appController.userSettings != null) {
      _settings.value = appController.userSettings;
    }
  }

  /// Listen to settings changes from other controllers
  void onSettingsChanged(UserSettings newSettings) {
    _settings.value = newSettings;

    // Recalculate next notification time
    if (newSettings.isNotificationEnabled) {
      _nextNotificationTime.value = newSettings.calculateNextNotificationTime();
    } else {
      _nextNotificationTime.value = null;
    }
  }
}
