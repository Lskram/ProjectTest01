// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSessionAdapter extends TypeAdapter<NotificationSession> {
  @override
  final int typeId = 5;

  @override
  NotificationSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSession(
      id: fields[0] as String,
      scheduledTime: fields[1] as DateTime,
      actualStartTime: fields[2] as DateTime?,
      completedTime: fields[3] as DateTime?,
      painPointId: fields[4] as int,
      treatmentIds: (fields[5] as List).cast<int>(),
      status: fields[6] as SessionStatus,
      snoozeCount: fields[7] as int,
      snoozeTimes: (fields[8] as List).cast<DateTime>(),
      treatmentCompleted: (fields[9] as List?)?.cast<bool>(),
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduledTime)
      ..writeByte(2)
      ..write(obj.actualStartTime)
      ..writeByte(3)
      ..write(obj.completedTime)
      ..writeByte(4)
      ..write(obj.painPointId)
      ..writeByte(5)
      ..write(obj.treatmentIds)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.snoozeCount)
      ..writeByte(8)
      ..write(obj.snoozeTimes)
      ..writeByte(9)
      ..write(obj.treatmentCompleted)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionStatusHiveAdapter extends TypeAdapter<SessionStatusHive> {
  @override
  final int typeId = 6;

  @override
  SessionStatusHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatusHive.pending;
      case 1:
        return SessionStatusHive.completed;
      case 2:
        return SessionStatusHive.snoozed;
      case 3:
        return SessionStatusHive.skipped;
      default:
        return SessionStatusHive.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatusHive obj) {
    switch (obj) {
      case SessionStatusHive.pending:
        writer.writeByte(0);
        break;
      case SessionStatusHive.completed:
        writer.writeByte(1);
        break;
      case SessionStatusHive.snoozed:
        writer.writeByte(2);
        break;
      case SessionStatusHive.skipped:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
