import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/user_settings.dart';
import 'database_service.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  /// Main permission flow with hasRequestedPermissions check
  Future<bool> requestPermissions() async {
    try {
      final settings = await DatabaseService.instance.loadSettings();

      // ถ้าเคยขออนุญาติแล้ว ให้เช็คสถานะปัจจุบัน
      if (settings.hasRequestedPermissions) {
        debugPrint(
            '🔐 Permissions already requested, checking current status...');
        return await checkCurrentPermissionStatus();
      }

      // ขออนุญาติครั้งแรก
      debugPrint('🔐 Requesting permissions for first time...');
      final result = await _requestAllPermissions();

      // บันทึกว่าเคยขออนุญาติแล้ว
      final updatedSettings = settings.copyWith(hasRequestedPermissions: true);
      await DatabaseService.instance.saveSettings(updatedSettings);

      return result;
    } catch (e) {
      debugPrint('❌ Error in requestPermissions: $e');
      return false;
    }
  }

  /// Check current permission status without requesting
  Future<bool> checkCurrentPermissionStatus() async {
    try {
      final permissions = [
        Permission.notification,
        if (GetPlatform.isAndroid) Permission.scheduleExactAlarm,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        debugPrint(
            '🔍 Permission ${permission.toString()}: ${status.toString()}');

        if (!status.isGranted) {
          // Show dialog for permanently denied permissions
          if (status.isPermanentlyDenied) {
            await _showPermanentlyDeniedDialog(permission);
          }
          return false;
        }
      }

      debugPrint('✅ All permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> _requestAllPermissions() async {
    try {
      // Step 1: Notification permission
      final notificationGranted = await _requestNotificationPermission();
      if (!notificationGranted) {
        debugPrint('❌ Notification permission denied');
        return false;
      }

      // Step 2: Exact alarm permission (Android 12+)
      if (GetPlatform.isAndroid) {
        final alarmGranted = await _requestExactAlarmPermission();
        if (!alarmGranted) {
          debugPrint('❌ Exact alarm permission denied');
          return false;
        }
      }

      debugPrint('✅ All permissions granted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Request notification permission with explanation
  Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Show explanation dialog first
        final shouldRequest = await _showPermissionExplanationDialog(
          'การแจ้งเตือน',
          'แอปต้องการอนุญาติส่งการแจ้งเตือนเพื่อเตือนให้คุณออกกำลังกายตามเวลาที่กำหนด',
        );

        if (!shouldRequest) return false;

        final result = await Permission.notification.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        await _showPermanentlyDeniedDialog(Permission.notification);
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request exact alarm permission
  Future<bool> _requestExactAlarmPermission() async {
    try {
      if (!GetPlatform.isAndroid) return true;

      final status = await Permission.scheduleExactAlarm.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Show explanation dialog
        final shouldRequest = await _showPermissionExplanationDialog(
          'การตั้งเวลาแม่นยำ',
          'แอปต้องการอนุญาติตั้งเวลาแจ้งเตือนแบบแม่นยำเพื่อให้การแจ้งเตือนทำงานได้อย่างถูกต้องแม้ในโหมดประหยัดแบตเตอรี่',
        );

        if (!shouldRequest) return false;

        final result = await Permission.scheduleExactAlarm.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        await _showPermanentlyDeniedDialog(Permission.scheduleExactAlarm);
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error requesting exact alarm permission: $e');
      return false;
    }
  }

  /// Show explanation dialog before requesting permission
  Future<bool> _showPermissionExplanationDialog(
      String permissionName, String reason) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Text('ต้องการอนุญาติ$permissionName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason),
                const SizedBox(height: 16),
                const Text(
                  'แอปจะไม่เก็บข้อมูลส่วนตัวใดๆ และทำงานแบบ offline เท่านั้น',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('ไม่อนุญาต'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('อนุญาต'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  /// Show dialog for permanently denied permissions
  Future<void> _showPermanentlyDeniedDialog(Permission permission) async {
    String permissionName;
    String description;

    switch (permission) {
      case Permission.notification:
        permissionName = 'การแจ้งเตือน';
        description = 'เพื่อให้แอปสามารถแจ้งเตือนให้คุณออกกำลังกายได้';
        break;
      case Permission.scheduleExactAlarm:
        permissionName = 'การตั้งเวลาแม่นยำ';
        description =
            'เพื่อให้การแจ้งเตือนทำงานได้แม่นยำแม้ในโหมดประหยัดแบตเตอรี่';
        break;
      default:
        permissionName = 'สิทธิ์การใช้งาน';
        description = 'เพื่อให้แอปทำงานได้อย่างถูกต้อง';
    }

    await Get.dialog(
      AlertDialog(
        title: Text('ต้องการอนุญาติ$permissionName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            const Text(
              'กรุณาไปที่การตั้งค่าแอป > สิทธิ์ เพื่ออนุญาติการใช้งาน',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('ไปตั้งค่า'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Quick check methods
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  Future<bool> isExactAlarmPermissionGranted() async {
    if (!GetPlatform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  /// Get all permission statuses
  Future<Map<String, bool>> getAllPermissionStatuses() async {
    return {
      'notification': await isNotificationPermissionGranted(),
      'exactAlarm': await isExactAlarmPermissionGranted(),
    };
  }

  /// Check if all critical permissions are granted
  Future<bool> areAllCriticalPermissionsGranted() async {
    final statuses = await getAllPermissionStatuses();
    return statuses.values.every((granted) => granted);
  }

  /// Reset permission request flag (for testing)
  Future<void> resetPermissionRequestFlag() async {
    final settings = await DatabaseService.instance.loadSettings();
    final updatedSettings = settings.copyWith(hasRequestedPermissions: false);
    await DatabaseService.instance.saveSettings(updatedSettings);
    debugPrint('🔄 Permission request flag reset');
  }

  /// Test notification permission (for development)
  Future<void> testNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      debugPrint('🧪 Notification permission status: ${status.toString()}');

      if (status.isGranted) {
        debugPrint('✅ Notification permission is granted');
      } else {
        debugPrint('❌ Notification permission is not granted');
      }
    } catch (e) {
      debugPrint('❌ Error testing notification permission: $e');
    }
  }
}
