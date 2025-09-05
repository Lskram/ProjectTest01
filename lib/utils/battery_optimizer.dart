// lib/utils/battery_optimizer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 🔋 Office Syndrome Helper - Battery Optimization Guidance
/// แนะนำการตั้งค่าเพื่อประหยัดแบตเตอรี่และให้แอปทำงานได้อย่างต่อเนื่อง

class BatteryOptimizer {
  static const String _channelName = 'office_syndrome_helper/battery';
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// ข้อมูลการตั้งค่าแบตเตอรี่ตามยี่ห้อโทรศัพท์
  static const Map<String, BatteryOptimizationGuide> _brandGuides = {
    'samsung': BatteryOptimizationGuide(
      brandName: 'Samsung',
      steps: [
        'เปิด Settings → Device care → Battery',
        'แตะ "App power management"',
        'เลือก "Apps that won\'t be put to sleep"',
        'เพิ่ม "Office Syndrome Helper"',
        'กลับไปหน้า Battery → More battery settings',
        'ปิด "Adaptive battery" หรือเพิ่มแอปในรายการยกเว้น',
      ],
      additionalTips: [
        'ตั้งค่า "Auto-launch" ให้เปิดใน Smart Manager',
        'เพิ่มแอปใน "Protected apps" ใน Device care',
      ],
    ),
    'huawei': BatteryOptimizationGuide(
      brandName: 'Huawei',
      steps: [
        'เปิด Settings → Apps → Office Syndrome Helper',
        'แตะ "Battery" → "App launch"',
        'เปิด "Manage manually"',
        'เปิด "Auto-launch", "Secondary launch", "Run in background"',
        'กลับไป Settings → Battery → More battery settings',
        'เพิ่มแอปใน "Protected apps"',
      ],
      additionalTips: [
        'ปิด PowerGenie หรือเพิ่มแอปในรายการยกเว้น',
        'ตั้งค่า Phone Manager → Protected apps',
      ],
    ),
    'xiaomi': BatteryOptimizationGuide(
      brandName: 'Xiaomi / Redmi',
      steps: [
        'เปิด Settings → Apps → Manage apps',
        'หา "Office Syndrome Helper" → แตะ',
        'เลือก "Battery saver" → "No restrictions"',
        'เปิด "Autostart"',
        'กลับไป Settings → Battery & performance',
        'เลือก "Choose apps" → เพิ่มแอป',
      ],
      additionalTips: [
        'ปิด MIUI Optimization ใน Developer options',
        'ตั้งค่า Security → Autostart → เปิดแอป',
        'เพิ่มใน Memory & storage cleanup whitelist',
      ],
    ),
    'oppo': BatteryOptimizationGuide(
      brandName: 'OPPO',
      steps: [
        'เปิด Settings → Battery → Power saving mode',
        'เลือก "Custom" → "Background app management"',
        'หา "Office Syndrome Helper" → เปิด "Allow background activity"',
        'กลับไป Settings → Apps & notifications',
        'เลือก "Office Syndrome Helper" → "Battery usage"',
        'เลือก "Don\'t optimize"',
      ],
      additionalTips: [
        'ตั้งค่า Startup manager ให้อนุญาตแอป',
        'เพิ่มใน Phone Manager whitelist',
      ],
    ),
    'vivo': BatteryOptimizationGuide(
      brandName: 'Vivo',
      steps: [
        'เปิด Settings → Battery → Background app refresh',
        'หา "Office Syndrome Helper" → เปิด',
        'กลับไป Settings → More settings → Applications',
        'เลือก "Autostart" → เปิด "Office Syndrome Helper"',
        'เลือก "High background power consumption" → เพิ่มแอป',
      ],
      additionalTips: [
        'ตั้งค่า iManager → App manager → Autostart management',
        'เพิ่มใน Whitelist ของ Smart power',
      ],
    ),
    'oneplus': BatteryOptimizationGuide(
      brandName: 'OnePlus',
      steps: [
        'เปิด Settings → Battery → Battery optimization',
        'เลือก "All apps" → หา "Office Syndrome Helper"',
        'เลือก "Don\'t optimize"',
        'กลับไป Settings → Apps & notifications',
        'เลือก "Office Syndrome Helper" → "Advanced" → "Battery"',
        'เปิด "Background activity"',
      ],
      additionalTips: [
        'ปิด Adaptive Battery หรือเพิ่มแอปในรายการยกเว้น',
        'ตั้งค่า Recent apps lock',
      ],
    ),
  };

  /// ตรวจสอบข้อมูลอุปกรณ์
  static Future<DeviceInfo> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return DeviceInfo(
        brand: androidInfo.brand.toLowerCase(),
        model: androidInfo.model,
        manufacturer: androidInfo.manufacturer.toLowerCase(),
        androidVersion: androidInfo.version.release,
        apiLevel: androidInfo.version.sdkInt,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return DeviceInfo(
        brand: 'apple',
        model: iosInfo.model,
        manufacturer: 'apple',
        androidVersion: iosInfo.systemVersion,
        apiLevel: 0,
      );
    }

    return DeviceInfo(
      brand: 'unknown',
      model: 'unknown',
      manufacturer: 'unknown',
      androidVersion: 'unknown',
      apiLevel: 0,
    );
  }

  /// รับคำแนะนำการประหยัดแบตเตอรี่ตามยี่ห้อ
  static Future<BatteryOptimizationGuide> getBatteryGuide() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final brand = deviceInfo.manufacturer.toLowerCase();

      // หาคำแนะนำตามยี่ห้อ
      BatteryOptimizationGuide? guide = _brandGuides[brand];

      // หากไม่พบยี่ห้อ ลองหาจาก brand name
      if (guide == null) {
        for (final entry in _brandGuides.entries) {
          if (brand.contains(entry.key) ||
              deviceInfo.brand.contains(entry.key)) {
            guide = entry.value;
            break;
          }
        }
      }

      // หากยังไม่พบ ใช้คำแนะนำทั่วไป
      guide ??= _getGenericGuide(deviceInfo);

      return guide.copyWith(
        deviceModel: deviceInfo.model,
        androidVersion: deviceInfo.androidVersion,
      );
    } catch (e) {
      debugPrint('❌ Error getting battery guide: $e');
      return _getGenericGuide(null);
    }
  }

  /// คำแนะนำทั่วไปสำหรับ Android
  static BatteryOptimizationGuide _getGenericGuide(DeviceInfo? deviceInfo) {
    return BatteryOptimizationGuide(
      brandName: deviceInfo?.manufacturer ?? 'Android',
      steps: [
        'เปิด Settings → Apps & notifications',
        'เลือก "Office Syndrome Helper"',
        'แตะ "Battery" → "Battery optimization"',
        'เลือก "All apps" → หา "Office Syndrome Helper"',
        'เลือก "Don\'t optimize"',
        'กลับไป App settings → "Permissions"',
        'ตรวจสอบให้ permissions ครบถ้วน',
      ],
      additionalTips: [
        'ตั้งค่า Do Not Disturb ให้อนุญาตแจ้งเตือนจากแอป',
        'เพิ่มแอปในหน้าจอหลักเพื่อป้องกันการลบออกจากหน่วยความจำ',
        'รีสตาร์ทโทรศัพท์หลังตั้งค่าแล้ว',
      ],
      deviceModel: deviceInfo?.model,
      androidVersion: deviceInfo?.androidVersion,
    );
  }

  /// เปิดหน้าตั้งค่าแบตเตอรี่
  static Future<bool> openBatterySettings() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('openBatteryOptimization');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error opening battery settings: $e');
      return false;
    }
  }

  /// เปิดหน้าตั้งค่าแอป
  static Future<bool> openAppSettings() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('openAppSettings');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// ตรวจสอบสถานะ Battery Optimization
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await _channel.invokeMethod('isBatteryOptimizationIgnored');
        return result == true;
      }
      return true; // iOS ไม่มี battery optimization
    } catch (e) {
      debugPrint('❌ Error checking battery optimization: $e');
      return false;
    }
  }

  /// ตรวจสอบว่าแอปสามารถทำงานในพื้นหลังได้หรือไม่
  static Future<BackgroundStatus> checkBackgroundStatus() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final isBatteryOptimized = !(await isBatteryOptimizationIgnored());

      return BackgroundStatus(
        canRunInBackground: !isBatteryOptimized,
        batteryOptimizationEnabled: isBatteryOptimized,
        deviceBrand: deviceInfo.manufacturer,
        recommendations:
            await _getRecommendations(deviceInfo, isBatteryOptimized),
      );
    } catch (e) {
      debugPrint('❌ Error checking background status: $e');
      return BackgroundStatus(
        canRunInBackground: false,
        batteryOptimizationEnabled: true,
        deviceBrand: 'unknown',
        recommendations: [],
      );
    }
  }

  /// รับคำแนะนำเพิ่มเติม
  static Future<List<String>> _getRecommendations(
      DeviceInfo deviceInfo, bool isBatteryOptimized) async {
    final recommendations = <String>[];

    if (isBatteryOptimized) {
      recommendations.addAll([
        'ปิดการประหยัดแบตเตอรี่สำหรับแอปนี้',
        'อนุญาตให้แอปทำงานในพื้นหลัง',
        'เพิ่มแอปในรายการแอปที่ได้รับการป้องกัน',
      ]);
    }

    if (deviceInfo.apiLevel >= 23) {
      recommendations.add('ตรวจสอบการตั้งค่า Doze mode');
    }

    if (deviceInfo.apiLevel >= 28) {
      recommendations.add('ตั้งค่า Adaptive Battery ให้เหมาะสม');
    }

    // คำแนะนำตามยี่ห้อ
    final brand = deviceInfo.manufacturer.toLowerCase();
    if (brand.contains('samsung')) {
      recommendations.addAll([
        'ตั้งค่า Device care → Battery → Apps ที่ไม่นอนหลับ',
        'ปิด Adaptive battery หรือเพิ่มแอปในรายการยกเว้น',
      ]);
    } else if (brand.contains('huawei')) {
      recommendations.addAll([
        'ตั้งค่า Protected apps ใน Phone Manager',
        'เปิด Manual management ใน App launch',
      ]);
    } else if (brand.contains('xiaomi')) {
      recommendations.addAll([
        'ตั้งค่า Autostart และ Background restrictions',
        'ปิด MIUI Optimization',
      ]);
    }

    return recommendations;
  }

  /// สร้าง Widget แสดงคำแนะนำ
  static Widget buildOptimizationGuide(
      BuildContext context, BatteryOptimizationGuide guide) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.battery_saver,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'การตั้งค่าแบตเตอรี่สำหรับ ${guide.brandName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (guide.deviceModel != null) ...[
              Text(
                'รุ่น: ${guide.deviceModel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'ขั้นตอนการตั้งค่า:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...guide.steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (guide.additionalTips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'เคล็ดลับเพิ่มเติม:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...guide.additionalTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            tip,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openBatterySettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('เปิดการตั้งค่า'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.apps),
                    label: const Text('ตั้งค่าแอป'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// สร้าง Widget แสดงสถานะพื้นหลัง
  static Widget buildBackgroundStatusCard(
      BuildContext context, BackgroundStatus status) {
    final statusColor =
        status.canRunInBackground ? Colors.green : Colors.orange;
    final statusIcon =
        status.canRunInBackground ? Icons.check_circle : Icons.warning;
    final statusText = status.canRunInBackground
        ? 'แอปสามารถทำงานในพื้นหลังได้'
        : 'แอปอาจหยุดทำงานในพื้นหลัง';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'สถานะการทำงาน',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (status.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'คำแนะนำ:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...status.recommendations.map((recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// แสดง Dialog คำแนะนำการประหยัดแบตเตอรี่
  static Future<void> showBatteryOptimizationDialog(
      BuildContext context) async {
    final guide = await getBatteryGuide();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('การตั้งค่าแบตเตอรี่'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: buildOptimizationGuide(context, guide),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ตรวจสอบและแสดงคำเตือนหากจำเป็น
  static Future<void> checkAndShowWarningIfNeeded(BuildContext context) async {
    final status = await checkBackgroundStatus();

    if (!status.canRunInBackground && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('แจ้งเตือนสำคัญ'),
            ],
          ),
          content: const Text(
            'แอปอาจหยุดส่งการแจ้งเตือนเมื่อทำงานในพื้นหลัง '
            'เนื่องจากการตั้งค่าประหยัดแบตเตอรี่\n\n'
            'ต้องการดูวิธีการแก้ไขหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ไม่ใช่ตอนนี้'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showBatteryOptimizationDialog(context);
              },
              child: const Text('ดูวิธีแก้ไข'),
            ),
          ],
        ),
      );
    }
  }
}

/// โมเดลข้อมูลอุปกรณ์
class DeviceInfo {
  final String brand;
  final String model;
  final String manufacturer;
  final String androidVersion;
  final int apiLevel;

  const DeviceInfo({
    required this.brand,
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.apiLevel,
  });
}

/// โมเดลคำแนะนำการประหยัดแบตเตอรี่
class BatteryOptimizationGuide {
  final String brandName;
  final List<String> steps;
  final List<String> additionalTips;
  final String? deviceModel;
  final String? androidVersion;

  const BatteryOptimizationGuide({
    required this.brandName,
    required this.steps,
    required this.additionalTips,
    this.deviceModel,
    this.androidVersion,
  });

  BatteryOptimizationGuide copyWith({
    String? brandName,
    List<String>? steps,
    List<String>? additionalTips,
    String? deviceModel,
    String? androidVersion,
  }) {
    return BatteryOptimizationGuide(
      brandName: brandName ?? this.brandName,
      steps: steps ?? this.steps,
      additionalTips: additionalTips ?? this.additionalTips,
      deviceModel: deviceModel ?? this.deviceModel,
      androidVersion: androidVersion ?? this.androidVersion,
    );
  }
}

/// โมเดลสถานะการทำงานในพื้นหลัง
class BackgroundStatus {
  final bool canRunInBackground;
  final bool batteryOptimizationEnabled;
  final String deviceBrand;
  final List<String> recommendations;

  const BackgroundStatus({
    required this.canRunInBackground,
    required this.batteryOptimizationEnabled,
    required this.deviceBrand,
    required this.recommendations,
  });
}

/// Tips สำหรับผู้ใช้ทั่วไป
class BatteryTips {
  static const List<String> generalTips = [
    '🔋 ตรวจสอบให้แน่ใจว่าแอปได้รับอนุญาตให้ทำงานในพื้นหลัง',
    '⚡ ปิดการประหยัดแบตเตอรี่สำหรับแอปนี้เฉพาะ',
    '📱 เพิ่มแอปไว้ในหน้าจอหลักเพื่อป้องกันการปิดอัตโนมัติ',
    '🔄 รีสตาร์ทโทรศัพท์หลังจากเปลี่ยนการตั้งค่าแล้ว',
    '⏰ ตั้งเวลาแจ้งเตือนให้เหมาะสมกับการใช้งาน',
    '🎯 เลือกจุดที่ปวดให้ตรงกับความต้องการ',
  ];

  static const List<String> advancedTips = [
    '🔧 เปิด Developer Options และปิด "Don\'t keep activities"',
    '💾 ตรวจสอบ Storage space ให้เพียงพอ',
    '📡 รักษาการเชื่อมต่ออินเทอร์เน็ตให้เสถียร',
    '🎨 ใช้ Dark mode เพื่อประหยัดแบตเตอรี่',
    '🔇 ปรับการตั้งค่าเสียงและการสั่นให้เหมาะสม',
  ];

  /// รับ tips ตามระดับผู้ใช้
  static List<String> getTipsForUser({bool isAdvancedUser = false}) {
    if (isAdvancedUser) {
      return [...generalTips, ...advancedTips];
    }
    return generalTips;
  }

  /// สร้าง Widget แสดง Tips
  static Widget buildTipsCard(BuildContext context,
      {bool isAdvancedUser = false}) {
    final tips = getTipsForUser(isAdvancedUser: isAdvancedUser);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'เคล็ดลับการใช้งาน',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
