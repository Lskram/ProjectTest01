import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:async';

// Service สำหรับทดสอบการแจ้งเตือน
class TestNotificationService {
  static TestNotificationService? _instance;
  static TestNotificationService get instance =>
      _instance ??= TestNotificationService._();
  TestNotificationService._();

  static const int _testNotificationId = 99999;
  Timer? _countdownTimer;

  /// ทดสอบการแจ้งเตือนพร้อม countdown
  Future<void> testNotification({int countdownSeconds = 3}) async {
    try {
      // แสดง countdown dialog
      await _showCountdownDialog(countdownSeconds);

      // ส่งการแจ้งเตือนทดสอบ
      await _sendTestNotification();

      Get.snackbar(
        '🧪 ทดสอบส่งแล้ว',
        'ตรวจสอบการแจ้งเตือนของคุณ',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถทดสอบการแจ้งเตือนได้: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// แสดง countdown dialog
  Future<void> _showCountdownDialog(int seconds) async {
    return Get.dialog(
      PopScope(
        canPop: false, // ป้องกันการปิด dialog
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              int remainingSeconds = seconds;

              // เริ่ม countdown timer
              _countdownTimer?.cancel();
              _countdownTimer = Timer.periodic(
                const Duration(seconds: 1),
                (timer) {
                  if (remainingSeconds > 1) {
                    remainingSeconds--;
                    setState(() {});
                  } else {
                    timer.cancel();
                    Get.back(); // ปิด dialog
                  }
                },
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.science,
                      size: 40,
                      color: Colors.blue.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // หัวข้อ
                  const Text(
                    'ทดสอบการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ข้อความ countdown
                  Text(
                    'จะแจ้งเตือนใน $remainingSeconds วินาที',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Countdown circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: (seconds - remainingSeconds + 1) / seconds,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                      ),
                      Text(
                        remainingSeconds.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// ส่งการแจ้งเตือนทดสอบ
  Future<void> _sendTestNotification() async {
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifications.show(
      _testNotificationId,
      '🧪 ทดสอบการแจ้งเตือน',
      'การแจ้งเตือนทำงานปกติ! กดเพื่อเข้าแอป 💪',
      details,
      payload: 'test_notification',
    );
  }

  /// ยกเลิก countdown timer
  void dispose() {
    _countdownTimer?.cancel();
  }
}
