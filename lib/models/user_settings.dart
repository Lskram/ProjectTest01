import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0)
  List<int> selectedPainPointIds;

  @HiveField(1)
  int notificationInterval; // in minutes

  @HiveField(2)
  bool isNotificationEnabled;

  @HiveField(3)
  bool isSoundEnabled;

  @HiveField(4)
  bool isVibrationEnabled;

  @HiveField(5)
  String workStartTime; // HH:mm format

  @HiveField(6)
  String workEndTime; // HH:mm format

  @HiveField(7)
  List<int> workingDays; // 1=Monday, 7=Sunday

  @HiveField(8)
  String? currentSessionId;

  @HiveField(9)
  DateTime? lastNotificationTime;

  @HiveField(10)
  bool hasCompletedOnboarding;

  // NEW CRITICAL FIELDS
  @HiveField(11)
  bool hasRequestedPermissions;

  @HiveField(12)
  List<String>? breakTimes; // ["12:00-13:00", "15:00-15:15"] format

  @HiveField(13)
  String? lastNotificationSessionId;

  @HiveField(14)
  int snoozeInterval; // in minutes, default 5

  @HiveField(15)
  bool isFirstTimeUser;

  UserSettings({
    this.selectedPainPointIds = const [],
    this.notificationInterval = 60,
    this.isNotificationEnabled = true,
    this.isSoundEnabled = true,
    this.isVibrationEnabled = true,
    this.workStartTime = '09:00',
    this.workEndTime = '17:00',
    this.workingDays = const [1, 2, 3, 4, 5], // Mon-Fri
    this.currentSessionId,
    this.lastNotificationTime,
    this.hasCompletedOnboarding = false,
    this.hasRequestedPermissions = false,
    this.breakTimes,
    this.lastNotificationSessionId,
    this.snoozeInterval = 5,
    this.isFirstTimeUser = true,
  });

  // Helper methods for time calculations
  DateTime get workStart {
    final parts = workStartTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime get workEnd {
    final parts = workEndTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  // Check if current time is within working hours
  bool isWithinWorkingHours(DateTime time) {
    final timeOfDay = time.hour * 60 + time.minute;
    final startMinutes = workStart.hour * 60 + workStart.minute;
    final endMinutes = workEnd.hour * 60 + workEnd.minute;

    return timeOfDay >= startMinutes && timeOfDay <= endMinutes;
  }

  // Check if current day is a working day
  bool isWorkingDay(int weekday) {
    return workingDays.contains(weekday);
  }

  // Check if current time is in break time
  bool isInBreakTime(DateTime time) {
    if (breakTimes == null || breakTimes!.isEmpty) return false;

    final timeMinutes = time.hour * 60 + time.minute;

    for (final breakTime in breakTimes!) {
      final parts = breakTime.split('-');
      if (parts.length != 2) continue;

      final startParts = parts[0].split(':');
      final endParts = parts[1].split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (timeMinutes >= startMinutes && timeMinutes <= endMinutes) {
        return true;
      }
    }

    return false;
  }

  // Calculate next notification time with fixed interval logic
  DateTime calculateNextNotificationTime() {
    if (lastNotificationTime == null) {
      // First time - start from now
      return DateTime.now().add(Duration(minutes: notificationInterval));
    } else {
      // Next time - from lastNotificationTime + interval
      return lastNotificationTime!.add(Duration(minutes: notificationInterval));
    }
  }

  // Check if we should notify now
  bool shouldNotifyNow(DateTime now) {
    // Check working day
    if (!isWorkingDay(now.weekday)) return false;

    // Check working hours
    if (!isWithinWorkingHours(now)) return false;

    // Check break time
    if (isInBreakTime(now)) return false;

    return true;
  }

  // Create default settings
  factory UserSettings.defaultSettings() {
    return UserSettings(
      selectedPainPointIds: [],
      notificationInterval: 60,
      isNotificationEnabled: true,
      isSoundEnabled: true,
      isVibrationEnabled: true,
      workStartTime: '09:00',
      workEndTime: '17:00',
      workingDays: [1, 2, 3, 4, 5],
      hasCompletedOnboarding: false,
      hasRequestedPermissions: false,
      breakTimes: ['12:00-13:00'], // Default lunch break
      snoozeInterval: 5,
      isFirstTimeUser: true,
    );
  }

  // Copy with method
  UserSettings copyWith({
    List<int>? selectedPainPointIds,
    int? notificationInterval,
    bool? isNotificationEnabled,
    bool? isSoundEnabled,
    bool? isVibrationEnabled,
    String? workStartTime,
    String? workEndTime,
    List<int>? workingDays,
    String? currentSessionId,
    DateTime? lastNotificationTime,
    bool? hasCompletedOnboarding,
    bool? hasRequestedPermissions,
    List<String>? breakTimes,
    String? lastNotificationSessionId,
    int? snoozeInterval,
    bool? isFirstTimeUser,
  }) {
    return UserSettings(
      selectedPainPointIds: selectedPainPointIds ?? this.selectedPainPointIds,
      notificationInterval: notificationInterval ?? this.notificationInterval,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      workingDays: workingDays ?? this.workingDays,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      lastNotificationTime: lastNotificationTime ?? this.lastNotificationTime,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasRequestedPermissions:
          hasRequestedPermissions ?? this.hasRequestedPermissions,
      breakTimes: breakTimes ?? this.breakTimes,
      lastNotificationSessionId:
          lastNotificationSessionId ?? this.lastNotificationSessionId,
      snoozeInterval: snoozeInterval ?? this.snoozeInterval,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
    );
  }

  @override
  String toString() {
    return 'UserSettings(painPoints: $selectedPainPointIds, interval: ${notificationInterval}min, enabled: $isNotificationEnabled)';
  }
}
