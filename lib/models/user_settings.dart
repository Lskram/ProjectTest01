import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 2)
class UserSettings extends HiveObject {
  @HiveField(0)
  final bool notificationsEnabled;

  @HiveField(1)
  final int intervalMinutes; // ทุกกี่นาทีแจ้งเตือน

  @HiveField(2)
  final TimeOfDay workStartTime;

  @HiveField(3)
  final TimeOfDay workEndTime;

  @HiveField(4)
  final List<int> workDays; // 1=จันทร์, 7=อาทิตย์

  @HiveField(5)
  final List<BreakPeriod> breakPeriods;

  @HiveField(6)
  final bool soundEnabled;

  @HiveField(7)
  final bool vibrationEnabled;

  @HiveField(8)
  final int maxSnoozeCount; // เลื่อนได้สูงสุดกี่ครั้ง

  @HiveField(9)
  final List<int> snoozeOptions; // ตัวเลือกเลื่อน (นาที)

  @HiveField(10)
  final List<int> selectedPainPointIds; // จุดที่เลือกไว้ (สูงสุด 3)

  UserSettings({
    this.notificationsEnabled = true,
    this.intervalMinutes = 60,
    TimeOfDay? workStartTime, // ✅ เปลี่ยนเป็น nullable
    TimeOfDay? workEndTime, // ✅ เปลี่ยนเป็น nullable
    this.workDays = const [1, 2, 3, 4, 5], // จ-ศ
    this.breakPeriods = const [],
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.maxSnoozeCount = 3,
    this.snoozeOptions = const [5, 15, 30],
    this.selectedPainPointIds = const [],
  })  : workStartTime = workStartTime ??
            TimeOfDay(hour: 9, minute: 0), // ✅ ใช้ initializer list
        workEndTime = workEndTime ??
            TimeOfDay(hour: 18, minute: 0); // ✅ ใช้ initializer list

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
    );
  }

  // Helper methods
  bool get hasSelectedPainPoints => selectedPainPointIds.isNotEmpty;
  bool get isWorkDay => workDays.contains(DateTime.now().weekday);

  @override
  String toString() {
    return 'UserSettings{interval: ${intervalMinutes}min, painPoints: ${selectedPainPointIds.length}}';
  }
}

// Helper class สำหรับเวลาพัก
@HiveType(typeId: 3)
class TimeOfDay extends HiveObject {
  @HiveField(0)
  final int hour;

  @HiveField(1)
  final int minute;

  TimeOfDay({
    // ✅ ลบ const
    required this.hour,
    required this.minute,
  });

  // Convert to DateTime สำหรับวันนี้
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // แสดงเวลาแบบไทย
  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay copyWith({int? hour, int? minute}) {
    return TimeOfDay(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  String toString() => displayTime;

  // เพิ่ม equality operators สำหรับการเปรียบเทียบ
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

// Helper class สำหรับช่วงเวลาพัก
@HiveType(typeId: 4)
class BreakPeriod extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final TimeOfDay startTime;

  @HiveField(2)
  final TimeOfDay endTime;

  @HiveField(3)
  final bool isActive;

  BreakPeriod({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  // เช็คว่าเวลาปัจจุบันอยู่ในช่วงพักหรือไม่
  bool isCurrentlyInBreak() {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // ช่วงเวลาปกติ (ไม่ข้ามวัน)
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // ช่วงเวลาข้ามวัน (เช่น 23:00 - 01:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  BreakPeriod copyWith({
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
  }) {
    return BreakPeriod(
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'BreakPeriod{$name: ${startTime.displayTime}-${endTime.displayTime}}';
  }

  // เพิ่ม equality operators
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakPeriod &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      name.hashCode ^ startTime.hashCode ^ endTime.hashCode ^ isActive.hashCode;
}
