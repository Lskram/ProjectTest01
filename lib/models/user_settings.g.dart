// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 2;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      notificationsEnabled: fields[0] as bool,
      intervalMinutes: fields[1] as int,
      workStartTime: fields[2] as TimeOfDay?,
      workEndTime: fields[3] as TimeOfDay?,
      workDays: (fields[4] as List).cast<int>(),
      breakPeriods: (fields[5] as List).cast<BreakPeriod>(),
      soundEnabled: fields[6] as bool,
      vibrationEnabled: fields[7] as bool,
      maxSnoozeCount: fields[8] as int,
      snoozeOptions: (fields[9] as List).cast<int>(),
      selectedPainPointIds: (fields[10] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.intervalMinutes)
      ..writeByte(2)
      ..write(obj.workStartTime)
      ..writeByte(3)
      ..write(obj.workEndTime)
      ..writeByte(4)
      ..write(obj.workDays)
      ..writeByte(5)
      ..write(obj.breakPeriods)
      ..writeByte(6)
      ..write(obj.soundEnabled)
      ..writeByte(7)
      ..write(obj.vibrationEnabled)
      ..writeByte(8)
      ..write(obj.maxSnoozeCount)
      ..writeByte(9)
      ..write(obj.snoozeOptions)
      ..writeByte(10)
      ..write(obj.selectedPainPointIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final int typeId = 3;

  @override
  TimeOfDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeOfDay(
      hour: fields[0] as int,
      minute: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.hour)
      ..writeByte(1)
      ..write(obj.minute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreakPeriodAdapter extends TypeAdapter<BreakPeriod> {
  @override
  final int typeId = 4;

  @override
  BreakPeriod read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreakPeriod(
      name: fields[0] as String,
      startTime: fields[1] as TimeOfDay,
      endTime: fields[2] as TimeOfDay,
      isActive: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BreakPeriod obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
