import 'package:hive/hive.dart';

part 'notification_session.g.dart';

enum SessionStatus {
  pending, // รอทำ
  completed, // ทำเสร็จ
  snoozed, // เลื่อน
  skipped, // ข้าม
}

@HiveType(typeId: 5)
class NotificationSession extends HiveObject {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final DateTime scheduledTime; // เวลาที่ตั้งไว้

  @HiveField(2)
  final DateTime? actualStartTime; // เวลาที่เริ่มทำจริง

  @HiveField(3)
  final DateTime? completedTime; // เวลาที่ทำเสร็จ

  @HiveField(4)
  final int painPointId; // จุดที่สุ่มได้

  @HiveField(5)
  final List<int> treatmentIds; // ท่าที่สุ่มได้ (2 ท่า)

  @HiveField(6)
  final SessionStatus status;

  @HiveField(7)
  final int snoozeCount; // เลื่อนไปกี่ครั้งแล้ว

  @HiveField(8)
  final List<DateTime> snoozeTimes; // เวลาที่เลื่อนแต่ละครั้ง

  @HiveField(9)
  final List<bool> treatmentCompleted; // ท่าไหนทำเสร็จแล้ว

  @HiveField(10)
  final String? notes; // บันทึกเพิ่มเติม (ถ้ามี)

  NotificationSession({
    required this.id,
    required this.scheduledTime,
    this.actualStartTime,
    this.completedTime,
    required this.painPointId,
    required this.treatmentIds,
    this.status = SessionStatus.pending,
    this.snoozeCount = 0,
    this.snoozeTimes = const [],
    List<bool>? treatmentCompleted,
    this.notes,
  }) : treatmentCompleted =
            treatmentCompleted ?? List.filled(treatmentIds.length, false);

  // Getter methods
  Duration? get sessionDuration {
    if (actualStartTime != null && completedTime != null) {
      return completedTime!.difference(actualStartTime!);
    }
    return null;
  }

  bool get isCompleted => status == SessionStatus.completed;
  bool get isPending => status == SessionStatus.pending;
  bool get isSkipped => status == SessionStatus.skipped;
  bool get canSnooze => snoozeCount < 3; // สามารถเลื่อนได้อีก

  int get completedTreatmentCount {
    return treatmentCompleted.where((completed) => completed).length;
  }

  bool get allTreatmentsCompleted {
    return treatmentCompleted.every((completed) => completed);
  }

  double get completionPercentage {
    if (treatmentCompleted.isEmpty) return 0.0;
    return completedTreatmentCount / treatmentCompleted.length;
  }

  // Helper methods
  NotificationSession copyWith({
    String? id,
    DateTime? scheduledTime,
    DateTime? actualStartTime,
    DateTime? completedTime,
    int? painPointId,
    List<int>? treatmentIds,
    SessionStatus? status,
    int? snoozeCount,
    List<DateTime>? snoozeTimes,
    List<bool>? treatmentCompleted,
    String? notes,
  }) {
    return NotificationSession(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      completedTime: completedTime ?? this.completedTime,
      painPointId: painPointId ?? this.painPointId,
      treatmentIds: treatmentIds ?? this.treatmentIds,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      snoozeTimes: snoozeTimes ?? this.snoozeTimes,
      treatmentCompleted: treatmentCompleted ?? this.treatmentCompleted,
      notes: notes ?? this.notes,
    );
  }

  // Mark specific treatment as completed
  NotificationSession markTreatmentCompleted(int index) {
    final newCompletedList = List<bool>.from(treatmentCompleted);
    if (index >= 0 && index < newCompletedList.length) {
      newCompletedList[index] = true;
    }

    return copyWith(
      treatmentCompleted: newCompletedList,
      actualStartTime: actualStartTime ?? DateTime.now(),
    );
  }

  // Mark session as completed
  NotificationSession markAsCompleted() {
    return copyWith(
      status: SessionStatus.completed,
      completedTime: DateTime.now(),
      treatmentCompleted: List.filled(treatmentIds.length, true),
    );
  }

  // Snooze session
  NotificationSession snooze(int minutes) {
    final newScheduledTime = DateTime.now().add(Duration(minutes: minutes));
    final newSnoozeTimes = List<DateTime>.from(snoozeTimes)
      ..add(DateTime.now());

    return copyWith(
      status: SessionStatus.snoozed,
      scheduledTime: newScheduledTime,
      snoozeCount: snoozeCount + 1,
      snoozeTimes: newSnoozeTimes,
    );
  }

  // Skip session
  NotificationSession skip() {
    return copyWith(
      status: SessionStatus.skipped,
      completedTime: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'NotificationSession{id: $id, status: $status, progress: ${(completionPercentage * 100).toInt()}%}';
  }
}

// Hive Type Adapter สำหรับ SessionStatus enum
@HiveType(typeId: 6)
enum SessionStatusHive {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  snoozed,
  @HiveField(3)
  skipped,
}
