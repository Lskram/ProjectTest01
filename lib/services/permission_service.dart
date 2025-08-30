import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  // 🔥 FIX 1.1: เช็คว่าเคยขออนุญาติแล้วหรือยัง
  bool get hasRequestedPermissions {
    final settings = DatabaseService.instance.getUserSettings();
    return settings.hasRequestedPermissions;
  }

  /// เช็คและขอ permissions ทั้งหมดที่ต้องการ (เฉพาะครั้งแรก)
  Future<bool> requestAllPermissions() async {
    // 🔥 FIX 1.1: เช็คก่อนว่าเคยขอแล้วหรือยัง
    if (hasRequestedPermissions) {
      debugPrint('✅ Permissions already requested previously');
      return await arePermissionsGranted();
    }

    debugPrint('🔐 First time requesting permissions...');
    final results = await _requestPermissions();
    final allGranted = results.values.every((status) => status == PermissionStatus.granted);

    // 🔥 FIX 1.1: บันทึกว่าได้ขออนุญาติแล้ว
    await _markPermissionsAsRequested();

    return allGranted;
  }

  /// บันทึกว่าได้ขออนุญาติแล้ว
  Future<void> _markPermissionsAsRequested() async {
    try {
      final currentSettings = DatabaseService.instance.getUserSettings();
      final updatedSettings = currentSettings.copyWith(
        hasRequestedPermissions: true,
      );
      await DatabaseService.instance.saveUserSettings(updatedSettings);
      debugPrint('✅ Marked permissions as requested');
    } catch (e) {
      debugPrint('❌ Error marking permissions as requested: $e');
    }
  }

  /// ขอ permissions แต่ละตัว
  Future<Map<Permission, PermissionStatus>> _requestPermissions() async {
    final permissions = <Permission>[];

    // Notification permission
    permissions.add(Permission.notification);

    // Schedule exact alarm (Android 12+)
    if (GetPlatform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        permissions.add(Permission.scheduleExactAlarm);
      }
    }

    // Request permissions
    return await permissions.request();
  }

  /// เช็คว่า permissions ทั้งหมดได้รับอนุญาติหรือไม่
  Future<bool> arePermissionsGranted() async {
    final notificationGranted = await Permission.notification.isGranted;
    final exactAlarmGranted = GetPlatform.isAndroid 
        ? await Permission.scheduleExactAlarm.isGranted 
        : true;

    return notificationGranted && exactAlarmGranted;
  }

  /// เช็ค permission เฉพาะ notification
  Future<bool> checkNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  /// ขอ notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  /// เช็ค exact alarm permission (Android 12+)
  Future<bool> checkExactAlarmPermission() async {
    if (!GetPlatform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  /// ขอ exact alarm permission
  Future<bool> requestExactAlarmPermission() async {
    if (!GetPlatform.isAndroid) return true;

    final status = await Permission.scheduleExactAlarm.request();
    return status == PermissionStatus.granted;
  }

  /// เช็ค permissions ทั้งหมดพร้อมรายละเอียด
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'notification': await checkNotificationPermission(),
      'exactAlarm': await checkExactAlarmPermission(),
    };
  }

  /// แสดง dialog อธิบาย permission
  Future<bool> showPermissionDialog(String permissionName, String reason) async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ต้องการอนุญาต $permissionName',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              reason,
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(
                  'ไม่อนุญาต',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('อนุญาต'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// แสดง dialog ไปตั้งค่า permission
  void showPermissionSettingsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: Colors.orange.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('ต้องการอนุญาต'),
          ],
        ),
        content: const Text(
          'แอปต้องการอนุญาตการแจ้งเตือนเพื่อให้บริการได้อย่างสมบูรณ์\n\n'
          'กรุณาไปที่การตั้งค่าเพื่ออนุญาต',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ไปตั้งค่า'),
          ),
        ],
      ),
    );
  }

  /// เช็คว่า permissions พร้อมใช้งานหรือไม่
  Future<bool> arePermissionsReady() async {
    final permissions = await checkAllPermissions();
    return permissions.values.every((granted) => granted);
  }

  /// ขอ permissions พร้อมแสดงคำอธิบาย (เฉพาะครั้งแรก)
  Future<bool> requestPermissionsWithExplanation() async {
    // 🔥 FIX 1.1: เช็คว่าเคยขอแล้วหรือยัง
    if (hasRequestedPermissions) {
      // ถ้าเคยขอแล้ว แค่เช็คสถานะปัจจุบัน
      final isReady = await arePermissionsReady();
      if (!isReady) {
        // ถ้ายังไม่ได้อนุญาต แสดง dialog ให้ไปตั้งค่า
        showPermissionSettingsDialog();
      }
      return isReady;
    }

    // ถ้ายังไม่เคยขอ ให้แสดง dialog อธิบาย
    final shouldRequest = await showPermissionDialog(
      'การแจ้งเตือน',
      'แอปต้องการอนุญาตการแจ้งเตือนเพื่อเตือนให้คุณออกกำลังกายในเวลาที่เหมาะสม\n\n'
          'การแจ้งเตือนจะช่วย:\n'
          '• เตือนให้ออกกำลังกายทุก 1 ชั่วโมง\n'
          '• ป้องกัน Office Syndrome\n'
          '• สร้างนิสัยดูแลสุขภาพ',
    );

    if (!shouldRequest) {
      // ผู้ใช้ไม่อนุญาต แต่ยังต้องบันทึกว่าได้ขอแล้ว
      await _markPermissionsAsRequested();
      return false;
    }

    // ขอ permissions
    final granted = await requestAllPermissions();

    if (!granted) {
      // ถ้าไม่ได้รับอนุญาต แสดงวิธีไปตั้งค่า
      showPermissionSettingsDialog();
      return false;
    }

    return true;
  }

  /// 🔥 FIX 1.1: รีเซ็ตสถานะการขออนุญาติ (สำหรับ testing)
  Future<void> resetPermissionState() async {
    if (!kDebugMode) return; // เฉพาะ debug mode
    
    try {
      final currentSettings = DatabaseService.instance.getUserSettings();
      final updatedSettings = currentSettings.copyWith(
        hasRequestedPermissions: false,
      );
      await DatabaseService.instance.saveUserSettings(updatedSettings);
      debugPrint('🔄 Permission state reset (debug only)');
    } catch (e) {
      debugPrint('❌ Error resetting permission state: $e');
    }
  }

  /// Debug: แสดงสถานะ permissions ทั้งหมด
  Future<void> debugPermissionStatus() async {
    if (!kDebugMode) return;

    final permissions = await checkAllPermissions();
    final hasRequested = hasRequestedPermissions;

    debugPrint('=== Permission Status ===');
    debugPrint('Has Requested Before: ${hasRequested ? "✅" : "❌"}');
    permissions.forEach((name, granted) {
      debugPrint('$name: ${granted ? "✅ Granted" : "❌ Denied"}');
    });
    debugPrint('=========================');
  }
}