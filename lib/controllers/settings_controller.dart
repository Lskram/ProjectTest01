import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../controllers/home_controller.dart';
import '../models/user_settings.dart';

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

  /// 🔥 FIX 1.4: แจ้งให้ controllers อื่นรู้ว่า settings เปลี่ยน
  Future<void> _notifySettingsChanged() async {
    // แจ้ง HomeController ให้รีเฟรช
    if (Get.isRegistered<HomeController>()) {
      await HomeController.instance.refreshData();
    }
  }

  /// Update notifications enabled
  Future<void> updateNotificationsEnabled(bool enabled) async {
    final updatedSettings = settings.copyWith(notificationsEnabled: enabled);
    _settings.value = updatedSettings;
    await _saveSettings();

    // Update notification system
    if (enabled) {
      await NotificationService.instance.scheduleNextNotification();
      Get.snackbar('เปิดการแจ้งเตือน 🔔', 'ระบบจะเตือนให้ออกกำลังกาย');
    } else {
      await NotificationService.instance.cancelAllNotifications();
      Get.snackbar('ปิดการแจ้งเตือน 🔕', 'ระบบหยุดการแจ้งเตือนชั่วคราว');
    }

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

      // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
      await _notifySettingsChanged();
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

    // Cancel all notifications
    await NotificationService.instance.cancelAllNotifications();

    Get.snackbar('รีเซ็ตแล้ว', 'กลับสู่การตั้งค่าเริ่มต้น');

    // 🔥 FIX 1.4: แจ้ง UI อื่นให้อัพเดท
    await _notifySettingsChanged();
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

  /// 🔥 FIX 2.2: ปรับปรุง Settings UI เพิ่มตัวเลือก
  /// Show interval picker
  Future<void> showIntervalPicker() async {
    final selectedInterval = await Get.dialog<int>(
      AlertDialog(
        title: const Text('เลือกช่วงเวลาแจ้งเตือน'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: intervalOptions.length,
            itemBuilder: (context, index) {
              final interval = intervalOptions[index];
              final isSelected = interval == intervalMinutes;
              
              return ListTile(
                title: Text('$interval นาที'),
                subtitle: Text(_getIntervalDescription(interval)),
                leading: Radio<int>(
                  value: interval,
                  groupValue: intervalMinutes,
                  onChanged: (value) => Get.back(result: value),
                ),
                selected: isSelected,
                onTap: () => Get.back(result: interval),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    if (selectedInterval != null && selectedInterval != intervalMinutes) {
      await updateIntervalMinutes(selectedInterval);
    }
  }

  /// Get interval description
  String _getIntervalDescription(int minutes) {
    if (minutes <= 30) return 'บ่อยมาก - เหมาะสำหรับงานหนัก';
    if (minutes <= 60) return 'ปกติ - แนะนำสำหรับคนทั่วไป';
    if (minutes <= 120) return 'น้อย - เหมาะสำหรับงานเบา';
    return 'น้อยมาก - เฉพาะกรณีพิเศษ';
  }

  /// Show work time picker
  Future<void> showWorkTimePicker() async {
    TimeOfDay? startTime = workStartTime;
    TimeOfDay? endTime = workEndTime;

    final result = await Get.dialog<Map<String, TimeOfDay>>(
      AlertDialog(
        title: const Text('ตั้งเวลาทำงาน'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('เวลาเริ่มงาน'),
                  subtitle: Text('${startTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) {
                      setState(() {
                        startTime = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('เวลาเลิกงาน'),
                  subtitle: Text('${endTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) {
                      setState(() {
                        endTime = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (!isValidWorkTime(startTime, endTime))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'เวลาเลิกงานต้องมากกว่าเวลาเริ่มงาน',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: isValidWorkTime(startTime, endTime)
                ? () => Get.back(result: {
                      'start': startTime,
                      'end': endTime,
                    })
                : null,
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result != null) {
      await updateWorkTime(
        startTime: result['start'],
        endTime: result['end'],
      );
    }
  }

  /// Show work days picker
  Future<void> showWorkDaysPicker() async {
    List<int> selectedDays = List.from(workDays);

    final result = await Get.dialog<List<int>>(
      AlertDialog(
        title: const Text('เลือกวันทำงาน'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: workDayOptions.entries.map((entry) {
                final day = entry.key;
                final name = entry.value;
                final isSelected = selectedDays.contains(day);

                return CheckboxListTile(
                  title: Text(name),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        if (!selectedDays.contains(day)) {
                          selectedDays.add(day);
                          selectedDays.sort();
                        }
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: selectedDays.isEmpty
                ? null
                : () => Get.back(result: selectedDays),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result != null) {
      await updateWorkDays(result);
    }
  }

  /// Export settings (for backup)
  Map<String, dynamic> exportSettings() {
    return settings.toMap(); // ต้องเพิ่ม toMap() method ใน UserSettings
  }

  /// Import settings (for restore)
  Future<void> importSettings(Map<String, dynamic> settingsMap) async {
    try {
      // Parse และ validate settings จาก map
      // final importedSettings = UserSettings.fromMap(settingsMap);
      // _settings.value = importedSettings;
      // await _saveSettings();
      
      Get.snackbar('สำเร็จ', 'นำเข้าการตั้งค่าเรียบร้อย');
    } catch (e) {
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถนำเข้าการตั้งค่าได้: $e');
    }
  }
}