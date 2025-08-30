import 'package:flutter/material.dart';
import '../services/database_service.dart';

// 🔥 FIX 1.2: Widget แสดงเวลาถัดไปแบบ Real-time
class LiveCountdownWidget extends StatelessWidget {
  final VoidCallback? onTestTap; // 🔥 FIX 2.1: ปุ่ม Test

  const LiveCountdownWidget({
    super.key,
    this.onTestTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      // 🔥 อัพเดททุกวินาทีเหมือนนาฬิกา
      stream:
          Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        return _buildNotificationStatus(now);
      },
    );
  }

  Widget _buildNotificationStatus(DateTime now) {
    final settings = DatabaseService.instance.getUserSettings();

    if (!settings.notificationsEnabled) {
      return _buildDisabledState();
    }

    final nextTime = settings.nextNotificationTime;
    if (nextTime == null) {
      return _buildCalculatingState();
    }

    final timeUntilNext = nextTime.difference(now);

    if (timeUntilNext.isNegative) {
      return _buildOverdueState();
    }

    return _buildActiveState(timeUntilNext, nextTime);
  }

  Widget _buildActiveState(Duration timeUntilNext, DateTime nextTime) {
    final hours = timeUntilNext.inHours;
    final minutes = timeUntilNext.inMinutes.remainder(60);
    final seconds = timeUntilNext.inSeconds.remainder(60);

    // สร้างข้อความแสดงเวลา
    String timeText;
    if (hours > 0) {
      timeText =
          '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      timeText = '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }

    // คำนวณ progress สำหรับ interval
    final settings = DatabaseService.instance.getUserSettings();
    final intervalDuration = Duration(minutes: settings.intervalMinutes);
    final totalSeconds = intervalDuration.inSeconds;
    final remainingSeconds = timeUntilNext.inSeconds;
    final progress = (totalSeconds - remainingSeconds) / totalSeconds;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'แจ้งเตือนถัดไป',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 🔥 FIX 2.1: ปุ่ม Test ข้างๆ
              if (onTestTap != null) _buildTestButton(),
            ],
          ),

          const SizedBox(height: 16),

          // เวลาถัดไปแบบใหญ่
          Text(
            'ใน $timeText',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),

          const SizedBox(height: 8),

          // เวลาที่แน่นอน
          Text(
            'เวลา ${_formatTime(nextTime)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ความคืบหน้า',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off,
            color: Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'การแจ้งเตือนปิดอยู่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'กำลังคำนวณเวลาถัดไป...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueState() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.red.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ถึงเวลาแจ้งเตือนแล้ว!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 FIX 2.1: ปุ่มทดสอบการแจ้งเตือน
  Widget _buildTestButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTestTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.science,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'ทดสอบ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }
}
