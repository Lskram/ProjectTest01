import 'package:get/get.dart';
import '../models/notification_session.dart';
import 'package:flutter/foundation.dart';
import '../models/treatment.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  // Reactive variables
  final _currentSession = Rxn<NotificationSession>();
  final _isNotificationsEnabled = true.obs;
  final _nextNotificationTime = Rxn<DateTime>();
  final _todaySessions = <NotificationSession>[].obs;

  // Getters
  NotificationSession? get currentSession => _currentSession.value;
  bool get isNotificationsEnabled => _isNotificationsEnabled.value;
  DateTime? get nextNotificationTime => _nextNotificationTime.value;
  List<NotificationSession> get todaySessions => _todaySessions;

  // Computed properties
  bool get hasActiveSession => _currentSession.value != null;

  int get todayCompletedCount =>
      _todaySessions.where((s) => s.isCompleted).length;

  int get todayTotalCount => _todaySessions.length;

  double get todayCompletionRate =>
      todayTotalCount > 0 ? todayCompletedCount / todayTotalCount : 0.0;

  @override
  void onInit() {
    super.onInit();
    _loadTodaySessions();
  }

  /// Initialize notification system
  Future<void> initializeNotifications() async {
    try {
      // Check if notifications are enabled in settings
      final settings = DatabaseService.instance.getUserSettings();
      _isNotificationsEnabled.value = settings.notificationsEnabled;

      if (!_isNotificationsEnabled.value) {
        debugPrint('📴 Notifications disabled in settings');
        return;
      }

      // Schedule next notification
      await NotificationService.instance.scheduleNextNotification();

      // Update next notification time (this would be calculated)
      _updateNextNotificationTime();

      debugPrint('✅ Notification system initialized');
    } catch (e) {
      debugPrint('❌ Initialize notifications error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาดในระบบแจ้งเตือน: $e');
    }
  }

  /// Load today's sessions
  Future<void> _loadTodaySessions() async {
    final today = DateTime.now();
    final sessions = DatabaseService.instance.getSessionsForDate(today);
    _todaySessions.assignAll(sessions);
  }

  /// Start notification session
  Future<void> startNotificationSession(String sessionId) async {
    try {
      final session =
          DatabaseService.instance.getNotificationSession(sessionId);
      if (session == null) {
        debugPrint('❌ Session not found: $sessionId');
        return;
      }

      // Update session with actual start time
      final startedSession = session.copyWith(
        actualStartTime: DateTime.now(),
        status: SessionStatus.pending,
      );

      await DatabaseService.instance.saveNotificationSession(startedSession);
      _currentSession.value = startedSession;

      debugPrint('▶️ Notification session started: $sessionId');
    } catch (e) {
      debugPrint('❌ Start session error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Mark treatment as completed
  Future<void> markTreatmentCompleted(int treatmentIndex) async {
    try {
      final session = _currentSession.value;
      if (session == null) return;

      // Update treatment completion
      final updatedSession = session.markTreatmentCompleted(treatmentIndex);
      await DatabaseService.instance.saveNotificationSession(updatedSession);
      _currentSession.value = updatedSession;

      debugPrint('✅ Treatment $treatmentIndex completed');
    } catch (e) {
      debugPrint('❌ Mark treatment completed error: $e');
    }
  }

  /// Complete entire session
  Future<void> completeSession() async {
    try {
      final session = _currentSession.value;
      if (session == null) return;

      // Mark as completed
      await NotificationService.instance.completeNotification(session.id);

      // Clear current session
      _currentSession.value = null;

      // Refresh today's sessions
      await _loadTodaySessions();

      // Update next notification time
      _updateNextNotificationTime();

      // Show success message
      Get.snackbar(
        'เยี่ยม! 🎉',
        'ออกกำลังกายเสร็จสิ้นแล้ว ร่างกายจะรู้สึกดีขึ้น',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      debugPrint('🎉 Session completed successfully');
    } catch (e) {
      debugPrint('❌ Complete session error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Snooze notification
  Future<void> snoozeNotification(int minutes) async {
    try {
      final session = _currentSession.value;
      if (session == null) return;

      await NotificationService.instance
          .snoozeNotification(session.id, minutes);

      // Clear current session
      _currentSession.value = null;

      // Update next notification time
      _updateNextNotificationTime();

      Get.snackbar(
        'เลื่อนแล้ว ⏰',
        'จะเตือนอีกครั้งใน $minutes นาที',
      );

      debugPrint('😴 Notification snoozed for $minutes minutes');
    } catch (e) {
      debugPrint('❌ Snooze error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Skip notification
  Future<void> skipNotification() async {
    try {
      final session = _currentSession.value;
      if (session == null) return;

      await NotificationService.instance.skipNotification(session.id);

      // Clear current session
      _currentSession.value = null;

      // Refresh today's sessions
      await _loadTodaySessions();

      // Update next notification time
      _updateNextNotificationTime();

      Get.snackbar('ข้ามแล้ว ⏭️', 'จะตั้งเวลาใหม่ให้อัตโนมัติ');

      debugPrint('⏭️ Notification skipped');
    } catch (e) {
      debugPrint('❌ Skip error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    try {
      _isNotificationsEnabled.value = enabled;

      // Update settings
      final settings = DatabaseService.instance.getUserSettings();
      final updatedSettings = settings.copyWith(notificationsEnabled: enabled);
      await DatabaseService.instance.saveUserSettings(updatedSettings);

      if (enabled) {
        await NotificationService.instance.scheduleNextNotification();
        _updateNextNotificationTime();
        Get.snackbar('เปิดการแจ้งเตือน 🔔', 'ระบบจะเตือนให้ออกกำลังกาย');
      } else {
        await NotificationService.instance.cancelAllNotifications();
        _nextNotificationTime.value = null;
        Get.snackbar('ปิดการแจ้งเตือน 🔕', 'ระบบหยุดการแจ้งเตือนชั่วคราว');
      }

      debugPrint('🔔 Notifications ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Toggle notifications error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Update next notification time (mock calculation)
  void _updateNextNotificationTime() {
    final settings = DatabaseService.instance.getUserSettings();
    if (settings.notificationsEnabled) {
      // Simple calculation - in real app this would be more complex
      final nextTime =
          DateTime.now().add(Duration(minutes: settings.intervalMinutes));
      _nextNotificationTime.value = nextTime;
    } else {
      _nextNotificationTime.value = null;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await NotificationService.instance.cancelAllNotifications();
      _currentSession.value = null;
      _nextNotificationTime.value = null;
      _isNotificationsEnabled.value = false;

      debugPrint('🔕 All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Cancel all notifications error: $e');
    }
  }

  /// Refresh today's data
  Future<void> refreshTodayData() async {
    await _loadTodaySessions();
    _updateNextNotificationTime();
  }

  /// Get pain point and treatments for session
  Map<String, dynamic>? getSessionData(NotificationSession session) {
    final painPoint = DatabaseService.instance
        .getAllPainPoints()
        .where((p) => p.id == session.painPointId)
        .firstOrNull;

    if (painPoint == null) return null;

    final treatments = session.treatmentIds
        .map((id) => DatabaseService.instance
            .getAllTreatments()
            .where((t) => t.id == id)
            .firstOrNull)
        .where((t) => t != null)
        .cast<Treatment>()
        .toList();

    return {
      'painPoint': painPoint,
      'treatments': treatments,
    };
  }
}
