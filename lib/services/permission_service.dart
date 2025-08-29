import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // เพิ่ม import นี้
import 'package:get/get.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  PermissionService._();

  /// เช็คและขอ permissions ทั้งหมดที่ต้องการ
  Future<bool> requestAllPermissions() async {
    final results = await _requestPermissions();
    return results.values.every((status) => status == PermissionStatus.granted);
  }

  /// ขอ permissions แต่ละตัว
  Future<Map<Permission, PermissionStatus>> _requestPermissions() async {
    final permissions = <Permission>[];

    // Notification permission
    permissions.add(Permission.notification);

    // Schedule exact alarm (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      permissions.add(Permission.scheduleExactAlarm);
    }

    // Request permissions
    return await permissions.request();
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

  /// เช็ค permissions ทั้งหมด
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'notification': await checkNotificationPermission(),
      'exactAlarm': await checkExactAlarmPermission(),
    };
  }

  /// แสดง dialog อธิบาย permission
  Future<bool> showPermissionDialog(
      String permissionName, String reason) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Text('ต้องการอนุญาต $permissionName'),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('ไม่อนุญาต'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
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
        title: const Text('ต้องการอนุญาต'),
        content: const Text(
            'แอปต้องการอนุญาตการแจ้งเตือนเพื่อให้บริการได้อย่างสมบูรณ์\n'
            'กรุณาไปที่การตั้งค่าเพื่ออนุญาต'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
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

  /// ขอ permissions พร้อมแสดงคำอธิบาย
  Future<bool> requestPermissionsWithExplanation() async {
    // เช็คก่อนว่ามีอนุญาตแล้วหรือไม่
    if (await arePermissionsReady()) return true;

    // อธิบายเหตุผล
    final shouldRequest = await showPermissionDialog(
      'การแจ้งเตือน',
      'แอปต้องการอนุญาตการแจ้งเตือนเพื่อเตือนให้คุณออกกำลังกายในเวลาที่เหมาะสม\n\n'
          'การแจ้งเตือนจะช่วย:\n'
          '• เตือนให้ออกกำลังกายทุก 1 ชั่วโมง\n'
          '• ป้องกัน Office Syndrome\n'
          '• สร้างนิสัยดูแลสุขภาพ',
    );

    if (!shouldRequest) return false;

    // ขอ permissions
    final granted = await requestAllPermissions();

    if (!granted) {
      // ถ้าไม่ได้รับอนุญาต แสดงวิธีไปตั้งค่า
      showPermissionSettingsDialog();
      return false;
    }

    return true;
  }

  /// Debug: แสดงสถานะ permissions ทั้งหมด
  Future<void> debugPermissionStatus() async {
    if (!kDebugMode) return; // ✅ แก้ไข: ใช้ kDebugMode แทน GetPlatform.isDebug

    final permissions = await checkAllPermissions();
    debugPrint('=== Permission Status ===');
    permissions.forEach((name, granted) {
      debugPrint('$name: ${granted ? "✅ Granted" : "❌ Denied"}');
    });
    debugPrint('=========================');
  }
}
