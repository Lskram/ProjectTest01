import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final settingsController = SettingsController.instance;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Notifications Section
            _buildSectionCard(
              icon: Icons.notifications,
              title: 'การแจ้งเตือน',
              children: [
                _buildSwitchTile(
                  title: 'เปิด/ปิดการแจ้งเตือน',
                  subtitle: 'รับการแจ้งเตือนให้ออกกำลังกาย',
                  value: settingsController.notificationsEnabled,
                  onChanged: settingsController.updateNotificationsEnabled,
                ),
                _buildListTile(
                  title: 'ช่วงเวลาแจ้งเตือน',
                  subtitle: 'ทุก ${settingsController.intervalMinutes} นาที',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showIntervalPicker(context, settingsController),
                ),
                _buildListTile(
                  title: 'เวลาทำงาน',
                  subtitle:
                      '${settingsController.workStartTime.displayTime} - ${settingsController.workEndTime.displayTime}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showWorkTimePicker(context, settingsController),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pain Points Section
            _buildSectionCard(
              icon: Icons.healing,
              title: 'จุดที่ปวด',
              children: [
                _buildListTile(
                  title: 'แก้ไขจุดที่เลือก',
                  subtitle: 'เลือกจุดที่คุณปวดบ่อย (สูงสุด 3 จุด)',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPainPointSelector(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sound & Vibration Section
            _buildSectionCard(
              icon: Icons.volume_up,
              title: 'เสียงและการสั่น',
              children: [
                _buildSwitchTile(
                  title: 'เสียงแจ้งเตือน',
                  subtitle: 'เปิด/ปิดเสียงเมื่อมีการแจ้งเตือน',
                  value: settingsController.soundEnabled,
                  onChanged: settingsController.updateSoundEnabled,
                ),
                _buildSwitchTile(
                  title: 'การสั่น',
                  subtitle: 'เปิด/ปิดการสั่นเมื่อมีการแจ้งเตือน',
                  value: settingsController.vibrationEnabled,
                  onChanged: settingsController.updateVibrationEnabled,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Other Settings
            _buildSectionCard(
              icon: Icons.settings,
              title: 'อื่นๆ',
              children: [
                _buildListTile(
                  title: 'รีเซ็ตการตั้งค่า',
                  subtitle: 'กลับสู่การตั้งค่าเริ่มต้น',
                  trailing: const Icon(Icons.refresh),
                  onTap: () => _showResetDialog(context, settingsController),
                ),
                _buildListTile(
                  title: 'เกี่ยวกับแอป',
                  subtitle: 'Office Syndrome Helper v1.0.0',
                  trailing: const Icon(Icons.info_outline),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
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
            child: Row(
              children: [
                Icon(icon, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showIntervalPicker(
      BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกช่วงเวลา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.intervalOptions.map((minutes) {
            return RadioListTile<int>(
              title: Text('$minutes นาที'),
              value: minutes,
              groupValue: controller.intervalMinutes,
              onChanged: (value) {
                if (value != null) {
                  controller.updateIntervalMinutes(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showWorkTimePicker(
      BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งเวลาทำงาน'),
        content: const Text('ฟีเจอร์นี้จะพร้อมใช้งานในเวอร์ชันถัดไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showPainPointSelector(BuildContext context) {
    // Navigate to pain point selection (similar to questionnaire)
    Get.dialog(
      AlertDialog(
        title: const Text('แก้ไขจุดที่ปวด'),
        content: const Text('ฟีเจอร์นี้จะพร้อมใช้งานในเวอร์ชันถัดไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตการตั้งค่า'),
        content: const Text('คุณแน่ใจหรือไม่ที่จะรีเซ็ตการตั้งค่าทั้งหมด?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              controller.resetToDefault();
              Navigator.pop(context);
            },
            child: const Text('รีเซ็ต'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Office Syndrome Helper',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.self_improvement,
        size: 48,
        color: Colors.blue.shade600,
      ),
      children: [
        const Text('แอปช่วยดูแลสุขภาพและป้องกัน Office Syndrome'),
        const SizedBox(height: 16),
        const Text('สร้างด้วย Flutter และ GetX'),
      ],
    );
  }
}
