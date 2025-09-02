// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreatmentAdapter extends TypeAdapter<Treatment> {
  @override
  final int typeId = 1;

  @override
  Treatment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Treatment(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      durationSeconds: fields[3] as int,
      painPointId: fields[4] as int,
      instructions: fields[5] as String,
      imagePath: fields[6] as String?,
      difficulty: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Treatment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.painPointId)
      ..writeByte(5)
      ..write(obj.instructions)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
