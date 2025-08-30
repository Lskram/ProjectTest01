import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/test_notification_service.dart';
import '../models/notification_session.dart';
import '../models/user_settings.dart';

class HomeController extends GetxController {
  static HomeController get instance => Get.find();

  // Reactive variables
  final _todaySessions = <NotificationSession>[].obs;
  final _isLoading = false.obs;
  final _userSettings = Rxn<UserSettings>();

  // Getters
  List<NotificationSession> get todaySessions => _todaySessions;
  bool get isLoading => _isLoading.value;
  UserSettings? get userSettings => _userSettings.value;

  // Computed properties
  int get todayTotalSessions => _todaySessions.length;

  int get todayCompletedSessions =>
      _todaySessions.where((s) => s.isCompleted).length;

  double get todayCompletionRate => todayTotalSessions > 0
      ? todayCompletedSessions / todayTotalSessions
      : 0.0;

  bool get notificationsEnabled => userSettings?.notificationsEnabled ?? false;

  DateTime? get nextNotificationTime => userSettings?.nextNotificationTime;

  // 🔥 FIX 1.2: Real-time countdown ทำใน Widget แล้ว ไม่ต้องมี Timer ใน Controller

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  @override
  void onReady() {
    super.onReady();
    // 🔥 FIX 1.4: Listen การเปลี่ยนแปลงจาก Settings
    _setupSettingsListener();
  }

  /// โหลดข้อมูลทั้งหมด
  Future<void> _loadData() async {
    try {
      _isLoading.value = true;

      await _loadTodaySessions();
      await _loadUserSettings();

      debugPrint('✅ Home data loaded');
    } catch (e) {
      debugPrint('❌ Load home data error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// โหลด sessions วันนี้
  Future<void> _loadTodaySessions() async {
    final today = DateTime.now();
    final sessions = DatabaseService.instance.getSessionsForDate(today);
    _todaySessions.assignAll(sessions);
  }

  /// โหลด user settings
  Future<void> _loadUserSettings() async {
    final settings = DatabaseService.instance.getUserSettings();
    _userSettings.value = settings;
  }

  /// 🔥 FIX 1.4: ตั้งค่าการฟัง Settings เปลี่ยนแปลง
  void _setupSettingsListener() {
    // ฟังการเปลี่ยนแปลงของ settings ทุก 2 วินาที
    // (ในโครงการจริงควรใช้ Stream หรือ EventBus)
    ever(_userSettings, (settings) {
      if (settings != null) {
        debugPrint('🔄 Settings changed, refreshing UI...');
      }
    });
  }

  /// 🔥 FIX 1.4: รีเฟรชข้อมูลเมื่อ Settings เปลี่ยน
  Future<void> refreshData() async {
    debugPrint('🔄 Refreshing home data...');
    await _loadData();
  }

  /// Pull-to-refresh 🔥 FIX 2.2
  Future<void> onRefresh() async {
    await refreshData();

    // รีเฟรช notification system
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleNextNotification();
    }

    Get.snackbar(
      'รีเฟรชแล้ว ✨',
      'ข้อมูลได้รับการอัพเดทแล้ว',
      duration: const Duration(seconds: 1),
    );
  }

  /// 🔥 FIX 2.1: ทดสอบการแจ้งเตือน
  Future<void> testNotification() async {
    try {
      debugPrint('🧪 Testing notification...');
      await TestNotificationService.instance.testNotification();
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถทดสอบการแจ้งเตือนได้',
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
      );
    }
  }

  /// สลับการเปิด/ปิดการแจ้งเตือน
  Future<void> toggleNotifications() async {
    try {
      final currentSettings = userSettings;
      if (currentSettings == null) return;

      final newEnabled = !currentSettings.notificationsEnabled;
      final updatedSettings = currentSettings.copyWith(
        notificationsEnabled: newEnabled,
      );

      await DatabaseService.instance.saveUserSettings(updatedSettings);
      _userSettings.value = updatedSettings;

      if (newEnabled) {
        await NotificationService.instance.scheduleNextNotification();
        Get.snackbar(
          'เปิดการแจ้งเตือน 🔔',
          'ระบบจะเตือนให้ออกกำลังกาย',
        );
      } else {
        await NotificationService.instance.cancelAllNotifications();
        Get.snackbar(
          'ปิดการแจ้งเตือน 🔕',
          'ระบบหยุดการแจ้งเตือน',
        );
      }

      debugPrint('🔔 Notifications toggled: $newEnabled');
    } catch (e) {
      debugPrint('❌ Toggle notifications error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// ไปหน้าออกกำลังกาย
  void goToExercise() {
    // สร้าง session ชั่วคราวหรือใช้ session ล่าสุด
    Get.toNamed('/todo');
  }

  /// ไปหน้าสถิติ
  void goToStatistics() {
    Get.toNamed('/statistics');
  }

  /// ไปหน้าตั้งค่า
  void goToSettings() {
    Get.toNamed('/settings');
  }

  /// ดูรายละเอียด session
  void viewSessionDetails(NotificationSession session) {
    Get.dialog(
      AlertDialog(
        title: Text('รายละเอียด Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เวลาตั้ง: ${_formatDateTime(session.scheduledTime)}'),
            Text('สถานะ: ${_getStatusText(session.status)}'),
            if (session.actualStartTime != null)
              Text('เวลาเริ่ม: ${_formatDateTime(session.actualStartTime!)}'),
            if (session.completedTime != null)
              Text('เวลาเสร็จ: ${_formatDateTime(session.completedTime!)}'),
            Text(
                'ความสำเร็จ: ${(session.completionPercentage * 100).toInt()}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  /// Format DateTime สำหรับแสดงผล
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// แปลงสถานะเป็นข้อความ
  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.pending:
        return 'รอทำ';
      case SessionStatus.completed:
        return 'เสร็จแล้ว';
      case SessionStatus.snoozed:
        return 'เลื่อน';
      case SessionStatus.skipped:
        return 'ข้าม';
      default:
        return 'ไม่ทราบ';
    }
  }

  /// เช็คสถานะการแจ้งเตือนปัจจุบัน
  String get notificationStatusText {
    if (!notificationsEnabled) {
      return 'การแจ้งเตือนปิดอยู่';
    }

    final nextTime = nextNotificationTime;
    if (nextTime == null) {
      return 'กำลังคำนวณเวลาถัดไป...';
    }

    final now = DateTime.now();
    final timeUntil = nextTime.difference(now);

    if (timeUntil.isNegative) {
      return 'ถึงเวลาแจ้งเตือนแล้ว!';
    }

    if (timeUntil.inDays > 0) {
      return 'แจ้งเตือนถัดไปพรุ่งนี้';
    }

    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes.remainder(60);

    if (hours > 0) {
      return 'แจ้งเตือนในอีก ${hours} ชั่วโมง ${minutes} นาที';
    } else {
      return 'แจ้งเตือนในอีก ${minutes} นาที';
    }
  }

  /// สีของสถานะการแจ้งเตือน
  Color get notificationStatusColor {
    if (!notificationsEnabled) {
      return Get.theme.colorScheme.onSurfaceVariant;
    }

    final nextTime = nextNotificationTime;
    if (nextTime == null) {
      return Get.theme.colorScheme.primary;
    }

    final now = DateTime.now();
    final timeUntil = nextTime.difference(now);

    if (timeUntil.isNegative) {
      return Get.theme.colorScheme.error;
    }

    if (timeUntil.inMinutes <= 10) {
      return Get.theme.colorScheme.tertiary;
    }

    return Get.theme.colorScheme.primary;
  }

  /// 🔥 เมื่อ dispose ให้ cleanup
  @override
  void onClose() {
    TestNotificationService.instance.dispose();
    super.onClose();
  }

  /// สถิติสำหรับแสดงในหน้า Home
  Map<String, dynamic> get todayStats {
    return {
      'total': todayTotalSessions,
      'completed': todayCompletedSessions,
      'rate': todayCompletionRate,
      'remaining': todayTotalSessions - todayCompletedSessions,
    };
  }

  /// เช็คว่าควรแสดงปุ่มออกกำลังกายไหม
  bool get shouldShowExerciseButton {
    // แสดงถ้ามี session ที่ยังไม่ได้ทำ
    return _todaySessions.any((s) => s.status == SessionStatus.pending);
  }

  /// หา session ที่ใกล้เคียงที่สุด
  NotificationSession? get nearestPendingSession {
    final pendingSessions =
        _todaySessions.where((s) => s.status == SessionStatus.pending).toList();

    if (pendingSessions.isEmpty) return null;

    // เรียงตามเวลาที่ใกล้ที่สุด
    pendingSessions.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return pendingSessions.first;
  }
}
