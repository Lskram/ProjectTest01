// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pain_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PainPointAdapter extends TypeAdapter<PainPoint> {
  @override
  final int typeId = 0;

  @override
  PainPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PainPoint(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      iconName: fields[3] as String,
      isSelected: fields[4] as bool,
      treatmentIds: (fields[5] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PainPoint obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.isSelected)
      ..writeByte(5)
      ..write(obj.treatmentIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PainPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
