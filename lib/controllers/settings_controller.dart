import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';
import '../models/pain_point.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import 'home_controller.dart';

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  // Reactive variables
  final _settings = Rxn<UserSettings>();
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _allPainPoints = <PainPoint>[].obs;
  final _permissionStatus = <String, bool>{}.obs;
  final _isTestingNotification = false.obs;

  // Getters
  UserSettings get settings => _settings.value ?? UserSettings.defaultSettings();
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  List<PainPoint> get allPainPoints => _allPainPoints;
  Map<String, bool> get permissionStatus => _permissionStatus;
  bool get isTestingNotification => _isTestingNotification.value;

  // Computed properties
  List<PainPoint> get selectedPainPoints =>
      _allPainPoints.where((p) => settings.selectedPainPointIds.contains(p.id)).toList();

  bool get hasAllPermissions => permissionStatus.values.every((granted) => granted);

  String get workingDaysText {
    const dayNames = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    return settings.workingDays
        .map((day) => dayNames[day - 1])
        .join(', ');
  }

  String get intervalText {
    if (settings.notificationInterval < 60) {
      return '${settings.notificationInterval} นาที';
    } else {
      final hours = settings.notificationInterval ~/ 60;
      final minutes = settings.notificationInterval % 60;
      if (minutes == 0) {
        return '${hours} ชั่วโมง';
      } else {
        return '${hours} ชั่วโมง ${minutes} นาที';
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('⚙️ SettingsController initialized');
    _initialize();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    try {
      _isLoading.value = true;
      
      await _loadSettings();
      await _loadPainPoints();
      await _checkPermissions();
      
    } catch (e) {
      debugPrint('❌ Error initializing SettingsController: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user settings
  Future<void> _loadSettings() async {
    try {
      final settings = await DatabaseService.instance.loadSettings();
      _settings.value = settings;
      debugPrint('⚙️ Settings loaded');
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
    }
  }

  /// Load all pain points
  Future<void> _loadPainPoints() async {
    try {
      final painPoints = await DatabaseService.instance.getAllPainPoints();
      _allPainPoints.assignAll(painPoints);
      debugPrint('⚙️ Pain points loaded: ${painPoints.length}');
    } catch (e) {
      debugPrint('❌ Error loading pain points: $e');
    }
  }

  /// Check all permissions status
  Future<void> _checkPermissions() async {
    try {
      final status = await PermissionService.instance.getAllPermissionStatuses();
      _permissionStatus.assignAll(status);
      debugPrint('⚙️ Permissions checked: $status');
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }
  }

  /// Save settings
  Future<void> _saveSettings(UserSettings newSettings) async {
    try {
      _isSaving.value = true;
      
      await DatabaseService.instance.saveSettings(newSettings);
      _settings.value = newSettings;
      
      // Notify home controller if it exists
      if (Get.isRegistered<HomeController>()) {
        HomeController.instance.onSettingsChanged(newSettings);
      }
      
      // Restart notifications if enabled
      if (newSettings.isNotificationEnabled) {
        await NotificationService.instance.startScheduling();
      } else {
        await NotificationService.instance.stopScheduling();
      }
      
      debugPrint('⚙️ Settings saved successfully');
      
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถบันทึกการตั้งค่าได้');
    } finally {
      _isSaving.value = false;
    }
  }

  /// Update notification interval
  Future<void> updateNotificationInterval(int minutes) async {
    final newSettings = settings.copyWith(notificationInterval: minutes);
    await _saveSettings(newSettings);
  }

  /// Toggle notification enabled
  Future<void> toggleNotifications(bool enabled) async {
    if (enabled && !hasAllPermissions) {
      final granted = await PermissionService.instance.requestPermissions();
      if (!granted) {
        Get.snackbar('ไม่สามารถเปิดใช้งาน', 'ต้องได้รับอนุญาติก่อน');
        return;
      }
      await _checkPermissions();
    }

    final newSettings = settings.copyWith(isNotificationEnabled: enabled);
    await _saveSettings(newSettings);
  }

  /// Toggle sound
  Future<void> toggleSound(bool enabled) async {
    final newSettings = settings.copyWith(isSoundEnabled: enabled);
    await _saveSettings(newSettings);
  }

  /// Toggle vibration
  Future<void> toggleVibration(bool enabled) async {
    final newSettings = settings.copyWith(isVibrationEnabled: enabled);
    await _saveSettings(newSettings);
  }

  /// Update work hours
  Future<void> updateWorkHours(String startTime, String endTime) async {
    final newSettings = settings.copyWith(
      workStartTime: startTime,
      workEndTime: endTime,
    );
    await _saveSettings(newSettings);
  }

  /// Update working days
  Future<void> updateWorkingDays(List<int> days) async {
    final newSettings = settings.copyWith(workingDays: days);
    await _saveSettings(newSettings);
  }

  /// Update break times
  Future<void> updateBreakTimes(List<String> breakTimes) async {
    final newSettings = settings.copyWith(breakTimes: breakTimes);
    await _saveSettings(newSettings);
  }

  /// Update snooze interval
  Future<void> updateSnoozeInterval(int minutes) async {
    final newSettings = settings.copyWith(snoozeInterval: minutes);
    await _saveSettings(newSettings);
  }

  /// Update selected pain points
  Future<void> updateSelectedPainPoints(List<int> painPointIds) async {
    if (painPointIds.length > 3) {
      Get.snackbar('ข้อจำกัด', 'เลือกได้สูงสุด 3 จุด');
      return;
    }

    if (painPointIds.isEmpty) {
      Get.snackbar('ข้อผิดพลาด', 'ต้องเลือกอย่างน้อย 1 จุดที่ปวด');
      return;
    }

    final newSettings = settings.copyWith(selectedPainPointIds: painPointIds);
    await _saveSettings(newSettings);
  }

  /// Toggle pain point selection
  void togglePainPoint(int painPointId) {
    final currentIds = List<int>.from(settings.selectedPainPointIds);
    
    if (currentIds.contains(painPointId)) {
      if (currentIds.length == 1) {
        Get.snackbar('ไม่สามารถยกเลิก', 'ต้องเลือกอย่างน้อย 1 จุดที่ปวด');
        return;
      }
      currentIds.remove(painPointId);
    } else {
      if (currentIds.length >= 3) {
        Get.snackbar('ข้อจำกัด', 'เลือกได้สูงสุด 3 จุด');
        return;
      }
      currentIds.add(painPointId);
    }
    
    updateSelectedPainPoints(currentIds);
  }

  /// Request permissions
  Future<void> requestPermissions() async {
    try {
      debugPrint('⚙️ Requesting permissions from settings...');
      
      final granted = await PermissionService.instance.requestPermissions();
      await _checkPermissions();
      
      if (granted) {
        Get.snackbar('สำเร็จ', 'ได้รับอนุญาติแล้ว');
      } else {
        Get.snackbar('ไม่สามารถดำเนินการได้', 'ต้องการอนุญาติเพื่อใช้งาน');
      }
      
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      Get.snackbar('ข้อผิดพลาด', 'เกิดข้อผิดพลาดในการขออนุญาติ');
    }
  }

  /// Test notification (NEW FEATURE)
  Future<void> testNotification() async {
    try {
      _isTestingNotification.value = true;
      debugPrint('🧪 Testing notification...');

      // Check permissions first
      if (!hasAllPermissions) {
        Get.snackbar('ไม่สามารถทดสอบได้', 'ต้องได้รับอนุญาติก่อน');
        return;
      }

      // Check if pain points are selected
      if (settings.selectedPainPointIds.isEmpty) {
        Get.snackbar('ไม่สามารถทดสอบได้', 'ต้องเลือกจุดที่ปวดก่อน');
        return;
      }

      // Send test notification
      await NotificationService.instance.testNotification();
      
      Get.snackbar(
        'ทดสอบสำเร็จ',
        'ส่งการแจ้งเตือนทดสอบแล้ว',
        duration: const Duration(seconds: 3),
      );
      
      debugPrint('✅ Test notification sent');
      
    } catch (e) {
      debugPrint('❌ Error testing notification: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถส่งการแจ้งเตือนทดสอบได้');
    } finally {
      _isTestingNotification.value = false;
    }
  }

  /// Factory reset
  Future<void> factoryReset() async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('รีเซ็ตการตั้งค่า'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลทั้งหมดและเริ่มต้นใหม่?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('รีเซ็ต', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      _isLoading.value = true;
      
      // Stop notifications
      await NotificationService.instance.stopScheduling();
      
      // Factory reset database
      await DatabaseService.instance.factoryReset();
      
      // Reload data
      await _loadSettings();
      await _loadPainPoints();
      await _checkPermissions();
      
      Get.snackbar('รีเซ็ตสำเร็จ', 'ข้อมูลทั้งหมดถูกลบและเริ่มต้นใหม่แล้ว');
      
    } catch (e) {
      debugPrint('❌ Error during factory reset: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถรีเซ็ตได้');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Export data
  Future<void> exportData() async {
    try {
      _isLoading.value = true;
      
      final data = await DatabaseService.instance.exportData();
      
      // Here you would typically save to file or share
      // For now, just show success message
      Get.snackbar(
        'ส่งออกสำเร็จ',
        'ข้อมูลถูกส่งออกแล้ว',
        duration: const Duration(seconds: 3),
      );
      
      debugPrint('✅ Data exported: ${data.keys}');
      
    } catch (e) {
      debugPrint('❌ Error exporting data: $e');
      Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถส่งออกข้อมูลได้');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get permission status text
  String getPermissionStatusText(String permission) {
    final granted = _permissionStatus[permission] ?? false;
    return granted ? 'อนุญาต' : 'ไม่อนุญาต';
  }

  /// Get permission status color
  Color getPermissionStatusColor(String permission) {
    final granted = _permissionStatus[permission] ?? false;
    return granted ? Colors.green : Colors.red;
  }

  /// Refresh data
  Future<void> refresh() async {
    await _initialize();
  }

  /// Validate settings before saving
  bool _validateSettings(UserSettings settings) {
    if (settings.selectedPainPointIds.isEmpty) {
      Get.snackbar('ข้อผิดพลาด', 'ต้องเลือกอย่างน้อย 1 จุดที่ปวด');
      return false;
    }

    if (settings.notificationInterval < 5 || settings.notificationInterval > 480) {
      Get.snackbar('ข้อผิดพลาด', 'ช่วงเวลาแจ้งเตือนต้องอยู่ระหว่าง 5-480 นาที');
      return false;
    }

    if (settings.workingDays.isEmpty) {
      Get.snackbar('ข้อผิดพลาด', 'ต้องเลือกอย่างน้อย 1 วันทำงาน');
      return false;
    }

    return true;
  }

  /// Show interval picker dialog
  Future<void> showIntervalPicker() async {
    final intervals = [15, 30, 45, 60, 90, 120, 180, 240, 360, 480];
    
    await Get.dialog(
      AlertDialog(
        title: const Text('เลือกช่วงเวลาแจ้งเตือน'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: intervals.length,
            itemBuilder: (context, index) {
              final interval = intervals[index];
              final isSelected = settings.notificationInterval == interval;
              
              return ListTile(
                title: Text(
                  interval < 60 
                      ? '${interval} นาที'
                      : '${interval ~/ 60} ชั่วโมง${interval % 60 > 0 ? ' ${interval % 60} นาที' : ''}',
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                selected: isSelected,
                onTap: () {
                  Get.back();
                  updateNotificationInterval(interval);
                },
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
  }
}