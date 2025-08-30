import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class BreakPeriod extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final TimeOfDay startTime;

  @HiveField(2)
  final TimeOfDay endTime;

  BreakPeriod({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  BreakPeriod copyWith({
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return BreakPeriod(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  final bool notificationsEnabled;

  @HiveField(1)
  final int intervalMinutes;

  @HiveField(2)
  final TimeOfDay workStartTime;

  @HiveField(3)
  final TimeOfDay workEndTime;

  @HiveField(4)
  final List<int> workDays; // 1=Monday, 7=Sunday

  @HiveField(5)
  final List<BreakPeriod> breakPeriods;

  @HiveField(6)
  final bool soundEnabled;

  @HiveField(7)
  final bool vibrationEnabled;

  @HiveField(8)
  final int maxSnoozeCount;

  @HiveField(9)
  final List<int> snoozeOptions; // in minutes

  @HiveField(10)
  final List<int> selectedPainPointIds;

  // 🔥 FIX 1.1: เพิ่ม permission tracking
  @HiveField(11)
  final bool hasRequestedPermissions;

  // 🔥 FIX 1.3: เพิ่ม last notification time สำหรับ fixed interval
  @HiveField(12)
  final DateTime? lastNotificationTime;

  UserSettings({
    this.notificationsEnabled = true,
    this.intervalMinutes = 60,
    this.workStartTime = const TimeOfDay(hour: 9, minute: 0),
    this.workEndTime = const TimeOfDay(hour: 17, minute: 0),
    this.workDays = const [1, 2, 3, 4, 5], // Monday to Friday
    this.breakPeriods = const [],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.maxSnoozeCount = 3,
    this.snoozeOptions = const [5, 10, 15],
    this.selectedPainPointIds = const [],
    this.hasRequestedPermissions = false, // 🔥 Default: ยังไม่เคยขอ
    this.lastNotificationTime, // 🔥 Default: null
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    int? intervalMinutes,
    TimeOfDay? workStartTime,
    TimeOfDay? workEndTime,
    List<int>? workDays,
    List<BreakPeriod>? breakPeriods,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? maxSnoozeCount,
    List<int>? snoozeOptions,
    List<int>? selectedPainPointIds,
    bool? hasRequestedPermissions, // 🔥 เพิ่ม
    DateTime? lastNotificationTime, // 🔥 เพิ่ม
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      workDays: workDays ?? this.workDays,
      breakPeriods: breakPeriods ?? this.breakPeriods,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      snoozeOptions: snoozeOptions ?? this.snoozeOptions,
      selectedPainPointIds: selectedPainPointIds ?? this.selectedPainPointIds,
      hasRequestedPermissions:
          hasRequestedPermissions ?? this.hasRequestedPermissions, // 🔥
      lastNotificationTime:
          lastNotificationTime ?? this.lastNotificationTime, // 🔥
    );
  }

  // Helper methods
  bool get isWorkingDay {
    final today = DateTime.now().weekday;
    return workDays.contains(today);
  }

  bool get isWorkingTime {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = workStartTime.hour * 60 + workStartTime.minute;
    final endMinutes = workEndTime.hour * 60 + workEndTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  bool get isInBreakPeriod {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final breakPeriod in breakPeriods) {
      final startMinutes =
          breakPeriod.startTime.hour * 60 + breakPeriod.startTime.minute;
      final endMinutes =
          breakPeriod.endTime.hour * 60 + breakPeriod.endTime.minute;

      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        return true;
      }
    }
    return false;
  }

  bool get shouldReceiveNotifications {
    return notificationsEnabled &&
        isWorkingDay &&
        isWorkingTime &&
        !isInBreakPeriod;
  }

  // 🔥 FIX 1.3: คำนวณเวลาแจ้งเตือนถัดไปแบบ fixed interval
  DateTime? get nextNotificationTime {
    if (!notificationsEnabled || lastNotificationTime == null) {
      return null;
    }

    // คำนวณจาก lastNotificationTime + interval
    var nextTime =
        lastNotificationTime!.add(Duration(minutes: intervalMinutes));

    // ถ้าเวลาถัดไปผ่านมาแล้ว ให้คำนวณใหม่จากตอนนี้
    final now = DateTime.now();
    while (nextTime.isBefore(now)) {
      nextTime = nextTime.add(Duration(minutes: intervalMinutes));
    }

    return nextTime;
  }

  @override
  String toString() {
    return 'UserSettings('
        'notificationsEnabled: $notificationsEnabled, '
        'intervalMinutes: $intervalMinutes, '
        'workStartTime: $workStartTime, '
        'workEndTime: $workEndTime, '
        'hasRequestedPermissions: $hasRequestedPermissions, '
        'lastNotificationTime: $lastNotificationTime'
        ')';
  }
}
