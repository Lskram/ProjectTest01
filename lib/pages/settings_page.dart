import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../models/pain_point.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController settingsController;

  @override
  void initState() {
    super.initState();
    // Initialize SettingsController if not exists
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    settingsController = SettingsController.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่า'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('รีเฟรช'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('ส่งออกข้อมูล'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore, color: Colors.red),
                  title: Text('รีเซ็ตทั้งหมด',
                      style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (settingsController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: settingsController.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildNotificationSection(),
              const SizedBox(height: 24),
              _buildPainPointsSection(),
              const SizedBox(height: 24),
              _buildWorkingHoursSection(),
              const SizedBox(height: 24),
              _buildPermissionsSection(),
              const SizedBox(height: 24),
              _buildTestSection(),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'การแจ้งเตือน',
      icon: Icons.notifications,
      children: [
        Obx(() => SwitchListTile(
              title: const Text('เปิดการแจ้งเตือน'),
              subtitle: Text(settingsController.settings.isNotificationEnabled
                  ? 'แจ้งเตือนทุก ${settingsController.intervalText}'
                  : 'ปิดการแจ้งเตือน'),
              value: settingsController.settings.isNotificationEnabled,
              onChanged: settingsController.toggleNotifications,
            )),
        Obx(() => ListTile(
              title: const Text('ช่วงเวลาแจ้งเตือน'),
              subtitle: Text(settingsController.intervalText),
              trailing: const Icon(Icons.chevron_right),
              enabled: settingsController.settings.isNotificationEnabled,
              onTap: settingsController.showIntervalPicker,
            )),
        Obx(() => SwitchListTile(
              title: const Text('เสียงแจ้งเตือน'),
              subtitle: const Text('เปิดเสียงเมื่อแจ้งเตือน'),
              value: settingsController.settings.isSoundEnabled,
              onChanged: settingsController.toggleSound,
              enabled: settingsController.settings.isNotificationEnabled,
            )),
        Obx(() => SwitchListTile(
              title: const Text('การสั่น'),
              subtitle: const Text('สั่นเครื่องเมื่อแจ้งเตือน'),
              value: settingsController.settings.isVibrationEnabled,
              onChanged: settingsController.toggleVibration,
              enabled: settingsController.settings.isNotificationEnabled,
            )),
        Obx(() => ListTile(
              title: const Text('เลื่อนการแจ้งเตือน'),
              subtitle: Text(
                  'เลื่อน ${settingsController.settings.snoozeInterval} นาที'),
              trailing: DropdownButton<int>(
                value: settingsController.settings.snoozeInterval,
                items: [5, 10, 15, 30]
                    .map((minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text('${minutes} นาที'),
                        ))
                    .toList(),
                onChanged: settingsController.settings.isNotificationEnabled
                    ? (value) => settingsController.updateSnoozeInterval(value!)
                    : null,
              ),
            )),
      ],
    );
  }

  Widget _buildPainPointsSection() {
    return _buildSection(
      title: 'จุดที่ปวดบ่อย',
      icon: Icons.healing,
      subtitle: 'เลือกได้สูงสุด 3 จุด',
      children: [
        Obx(() {
          if (settingsController.allPainPoints.isEmpty) {
            return const ListTile(
              title: Text('กำลังโหลด...'),
              leading: CircularProgressIndicator(),
            );
          }

          return Column(
            children: settingsController.allPainPoints.map((painPoint) {
              final isSelected = settingsController
                  .settings.selectedPainPointIds
                  .contains(painPoint.id);

              return CheckboxListTile(
                title: Text(painPoint.nameTh),
                subtitle: Text(painPoint.description),
                value: isSelected,
                onChanged: (_) =>
                    settingsController.togglePainPoint(painPoint.id),
                secondary: _getPainPointIcon(painPoint.id),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    return _buildSection(
      title: 'เวลาทำงาน',
      icon: Icons.access_time,
      children: [
        Obx(() => ListTile(
              title: const Text('เวลาทำงาน'),
              subtitle: Text(
                  '${settingsController.settings.workStartTime} - ${settingsController.settings.workEndTime}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showWorkHoursPicker,
            )),
        Obx(() => ListTile(
              title: const Text('วันทำงาน'),
              subtitle: Text(settingsController.workingDaysText),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showWorkingDaysPicker,
            )),
        Obx(() => ListTile(
              title: const Text('เวลาพัก'),
              subtitle: Text(
                  settingsController.settings.breakTimes?.join(', ') ??
                      'ไม่มี'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showBreakTimesPicker,
            )),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return _buildSection(
      title: 'สิทธิ์การใช้งาน',
      icon: Icons.security,
      children: [
        Obx(() {
          final permissions = settingsController.permissionStatus;

          return Column(
            children: [
              _buildPermissionItem(
                'การแจ้งเตือน',
                'notification',
                permissions['notification'] ?? false,
                'จำเป็นสำหรับส่งการแจ้งเตือนให้ออกกำลังกาย',
              ),
              _buildPermissionItem(
                'ตั้งเวลาแม่นยำ',
                'exactAlarm',
                permissions['exactAlarm'] ?? false,
                'ทำให้การแจ้งเตือนแม่นยำแม้ในโหมดประหยัดแบตเตอรี่',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: settingsController.hasAllPermissions
                      ? null
                      : settingsController.requestPermissions,
                  icon: Icon(settingsController.hasAllPermissions
                      ? Icons.check_circle
                      : Icons.security),
                  label: Text(settingsController.hasAllPermissions
                      ? 'ได้รับอนุญาติแล้ว'
                      : 'ขออนุญาติ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settingsController.hasAllPermissions
                        ? Colors.green
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTestSection() {
    return _buildSection(
      title: 'การทดสอบ',
      icon: Icons.science,
      children: [
        ListTile(
          title: const Text('ทดสอบการแจ้งเตือน'),
          subtitle: const Text('ส่งการแจ้งเตือนทดสอบเพื่อตรวจสอบการทำงาน'),
          trailing: Obx(() => settingsController.isTestingNotification
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send)),
          onTap: settingsController.isTestingNotification
              ? null
              : settingsController.testNotification,
        ),
        ListTile(
          title: const Text('ข้อมูลแอป'),
          subtitle: const Text('ดูข้อมูลเวอร์ชันและสถานะ'),
          trailing: const Icon(Icons.info_outline),
          onTap: _showAppInfo,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    String title,
    String key,
    bool granted,
    String description,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: granted ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          granted ? 'อนุญาต' : 'ไม่อนุญาต',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData _getPainPointIcon(int painPointId) {
    switch (painPointId) {
      case 1:
        return Icons.psychology; // Head
      case 2:
        return Icons.visibility; // Eyes
      case 3:
        return Icons.straighten; // Neck
      case 4:
        return Icons.fitness_center; // Shoulders
      case 5:
        return Icons.airline_seat_recline_normal; // Upper Back
      case 6:
        return Icons.airline_seat_recline_extra; // Lower Back
      case 7:
        return Icons.pan_tool; // Arms/Elbows
      case 8:
        return Icons.touch_app; // Wrists/Hands
      case 9:
        return Icons.directions_walk; // Legs
      case 10:
        return Icons.directions_run; // Feet
      default:
        return Icons.healing;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        settingsController.refresh();
        break;
      case 'export':
        settingsController.exportData();
        break;
      case 'reset':
        settingsController.factoryReset();
        break;
    }
  }

  void _showWorkHoursPicker() async {
    // Show time picker for work hours
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour:
            int.parse(settingsController.settings.workStartTime.split(':')[0]),
        minute:
            int.parse(settingsController.settings.workStartTime.split(':')[1]),
      ),
    );

    if (startTime != null) {
      final endTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour:
              int.parse(settingsController.settings.workEndTime.split(':')[0]),
          minute:
              int.parse(settingsController.settings.workEndTime.split(':')[1]),
        ),
      );

      if (endTime != null) {
        final startStr =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final endStr =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        settingsController.updateWorkHours(startStr, endStr);
      }
    }
  }

  void _showWorkingDaysPicker() async {
    const dayNames = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์'
    ];
    final selectedDays =
        List<int>.from(settingsController.settings.workingDays);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('เลือกวันทำงาน'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dayNames.length,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = selectedDays.contains(day);

                return CheckboxListTile(
                  title: Text(dayNames[index]),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedDays.add(day);
                      } else {
                        if (selectedDays.length > 1) {
                          selectedDays.remove(day);
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                settingsController.updateWorkingDays(selectedDays);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreakTimesPicker() async {
    final breakTimes = List<String>.from(
        settingsController.settings.breakTimes ?? ['12:00-13:00']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งเวลาพัก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('คุณสมบัตินี้กำลังพัฒนาในเวอร์ชันถัดไป'),
            const SizedBox(height: 16),
            const Text(
              'ปัจจุบันใช้เวลาพักเริ่มต้น: 12:00-13:00',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('ข้อมูลแอป'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ชื่อแอป:', 'Office Syndrome Helper'),
            _buildInfoRow('เวอร์ชัน:', '1.0.0'),
            _buildInfoRow('แพลตฟอร์ม:', 'Android'),
            _buildInfoRow('พัฒนาด้วย:', 'Flutter'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'แอปช่วยเตือนให้ออกกำลังกายเพื่อลดอาการ Office Syndrome ทำงานแบบ offline และไม่เก็บข้อมูลส่วนตัว',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
