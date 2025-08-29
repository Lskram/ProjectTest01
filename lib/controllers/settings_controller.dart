import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  // Reactive variables
  final _settings = Rxn<UserSettings>();
  final _isLoading = false.obs;

  // Getters
  UserSettings get settings => _settings.value ?? UserSettings();
  bool get isLoading => _isLoading.value;

  // Individual setting getters
  bool get notificationsEnabled => settings.notificationsEnabled;
  int get intervalMinutes => settings.intervalMinutes;
  TimeOfDay get workStartTime => settings.workStartTime;
  TimeOfDay get workEndTime => settings.workEndTime;
  List<int> get workDays => settings.workDays;
  List<BreakPeriod> get breakPeriods => settings.breakPeriods;
  bool get soundEnabled => settings.soundEnabled;
  bool get vibrationEnabled => settings.vibrationEnabled;
  int get maxSnoozeCount => settings.maxSnoozeCount;
  List<int> get snoozeOptions => settings.snoozeOptions;
  List<int> get selectedPainPointIds => settings.selectedPainPointIds;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load settings from database
  Future<void> loadSettings() async {
    try {
      _isLoading.value = true;
      final loadedSettings = DatabaseService.instance.getUserSettings();
      _settings.value = loadedSettings;
    } catch (e) {
      debugPrint('❌ Load settings error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Save settings to database
  Future<void> _saveSettings() async {
    try {
      await DatabaseService.instance.saveUserSettings(settings);
      debugPrint('✅ Settings saved');
    } catch (e) {
      debugPrint('❌ Save settings error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาดในการบันทึก: $e');
    }
  }

  /// Update notifications enabled
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final updatedSettings = settings.copyWith(notificationsEnabled: enabled);
    _settings.value = updatedSettings;
    await _saveSettings();

    // Update notification system - ใช้ service โดยตรงแทน controller
    if (enabled) {
      await NotificationService.instance.scheduleNextNotification();
      Get.snackbar('เปิดการแจ้งเตือน 🔔', 'ระบบจะเตือนให้ออกกำลังกาย');
    } else {
      await NotificationService.instance.cancelAllNotifications();
      Get.snackbar('ปิดการแจ้งเตือน 🔕', 'ระบบหยุดการแจ้งเตือนชั่วคราว');
    }
  }

  /// Update interval minutes
  Future<void> updateIntervalMinutes(int minutes) async {
    if (minutes < 15 || minutes > 240) {
      Get.snackbar('ข้อผิดพลาด', 'กรุณาเลือกช่วงเวลา 15-240 นาที');
      return;
    }

    final updatedSettings = settings.copyWith(intervalMinutes: minutes);
    _settings.value = updatedSettings;
    await _saveSettings();

    // Reschedule notifications
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleNextNotification();
    }

    Get.snackbar('อัปเดตแล้ว', 'เปลี่ยนช่วงเวลาแจ้งเตือนเป็น $minutes นาที');
  }

  /// Update work time
  Future<void> updateWorkTime({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    final updatedSettings = settings.copyWith(
      workStartTime: startTime,
      workEndTime: endTime,
    );
    _settings.value = updatedSettings;
    await _saveSettings();

    // Reschedule notifications
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleNextNotification();
    }

    Get.snackbar('อัปเดตแล้ว', 'เปลี่ยนเวลาทำงานแล้ว');
  }

  /// Update work days
  Future<void> updateWorkDays(List<int> days) async {
    final updatedSettings = settings.copyWith(workDays: days);
    _settings.value = updatedSettings;
    await _saveSettings();

    // Reschedule notifications
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleNextNotification();
    }

    final dayNames = days.map(_getDayName).join(', ');
    Get.snackbar('อัปเดตแล้ว', 'วันทำงาน: $dayNames');
  }

  /// Add break period
  Future<void> addBreakPeriod(BreakPeriod breakPeriod) async {
    final currentBreaks = List<BreakPeriod>.from(breakPeriods);
    currentBreaks.add(breakPeriod);

    final updatedSettings = settings.copyWith(breakPeriods: currentBreaks);
    _settings.value = updatedSettings;
    await _saveSettings();

    // Reschedule notifications
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleNextNotification();
    }

    Get.snackbar('เพิ่มแล้ว', 'เพิ่มช่วงเวลาพัก: ${breakPeriod.name}');
  }

  /// Remove break period
  Future<void> removeBreakPeriod(int index) async {
    final currentBreaks = List<BreakPeriod>.from(breakPeriods);
    if (index >= 0 && index < currentBreaks.length) {
      final removed = currentBreaks.removeAt(index);

      final updatedSettings = settings.copyWith(breakPeriods: currentBreaks);
      _settings.value = updatedSettings;
      await _saveSettings();

      // Reschedule notifications
      if (notificationsEnabled) {
        await NotificationService.instance.scheduleNextNotification();
      }

      Get.snackbar('ลบแล้ว', 'ลบช่วงเวลาพัก: ${removed.name}');
    }
  }

  /// Update sound enabled
  Future<void> updateSoundEnabled(bool enabled) async {
    final updatedSettings = settings.copyWith(soundEnabled: enabled);
    _settings.value = updatedSettings;
    await _saveSettings();

    Get.snackbar(enabled ? 'เปิดเสียง' : 'ปิดเสียง',
        'เสียงแจ้งเตือน${enabled ? "เปิด" : "ปิด"}แล้ว');
  }

  /// Update vibration enabled
  Future<void> updateVibrationEnabled(bool enabled) async {
    final updatedSettings = settings.copyWith(vibrationEnabled: enabled);
    _settings.value = updatedSettings;
    await _saveSettings();

    Get.snackbar(enabled ? 'เปิดการสั่น' : 'ปิดการสั่น',
        'การสั่นแจ้งเตือน${enabled ? "เปิด" : "ปิด"}แล้ว');
  }

  /// Update max snooze count
  Future<void> updateMaxSnoozeCount(int count) async {
    if (count < 0 || count > 10) {
      Get.snackbar('ข้อผิดพลาด', 'จำนวนครั้งเลื่อน 0-10 ครั้ง');
      return;
    }

    final updatedSettings = settings.copyWith(maxSnoozeCount: count);
    _settings.value = updatedSettings;
    await _saveSettings();

    Get.snackbar('อัปเดตแล้ว', 'เลื่อนได้สูงสุด $count ครั้ง');
  }

  /// Update snooze options
  Future<void> updateSnoozeOptions(List<int> options) async {
    final validOptions = options.where((o) => o > 0 && o <= 60).toList();

    final updatedSettings = settings.copyWith(snoozeOptions: validOptions);
    _settings.value = updatedSettings;
    await _saveSettings();

    Get.snackbar(
        'อัปเดตแล้ว', 'ตัวเลือกเลื่อน: ${validOptions.join(", ")} นาที');
  }

  /// Reset settings to default
  Future<void> resetToDefault() async {
    final defaultSettings = UserSettings();
    _settings.value = defaultSettings;
    await _saveSettings();

    Get.snackbar('รีเซ็ตแล้ว', 'กลับสู่การตั้งค่าเริ่มต้น');
  }

  /// Get day name in Thai
  String _getDayName(int day) {
    const dayNames = {
      1: 'จันทร์',
      2: 'อังคาร',
      3: 'พุธ',
      4: 'พฤหัสบดี',
      5: 'ศุกร์',
      6: 'เสาร์',
      7: 'อาทิตย์',
    };
    return dayNames[day] ?? '';
  }

  /// Get interval options for UI
  List<int> get intervalOptions => [15, 30, 45, 60, 90, 120, 180, 240];

  /// Get work day options for UI
  Map<int, String> get workDayOptions => {
        1: 'จันทร์',
        2: 'อังคาร',
        3: 'พุธ',
        4: 'พฤหัสบดี',
        5: 'ศุกร์',
        6: 'เสาร์',
        7: 'อาทิตย์',
      };

  /// Validate work time
  bool isValidWorkTime(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }
}
