import 'package:hive/hive.dart';

part 'treatment.g.dart';

@HiveType(typeId: 1)
class Treatment extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final int painPointId;

  @HiveField(5)
  final String instructions;

  @HiveField(6)
  final String? imagePath; // Optional รูปภาพประกอบ

  @HiveField(7)
  final int difficulty; // 1-3 (ง่าย-ยาก)

  Treatment({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.painPointId,
    required this.instructions,
    this.imagePath,
    this.difficulty = 1,
  });

  // Getter สำหรับแสดงระยะเวลาแบบเข้าใจง่าย
  String get durationText {
    if (durationSeconds < 60) {
      return '$durationSeconds วินาที';
    } else {
      final minutes = (durationSeconds / 60).floor();
      final seconds = durationSeconds % 60;
      if (seconds == 0) {
        return '$minutes นาที';
      } else {
        return '$minutes นาที $seconds วินาที';
      }
    }
  }

  // Getter สำหรับระดับความยาก
  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'ง่าย';
      case 2:
        return 'ปานกลาง';
      case 3:
        return 'ยาก';
      default:
        return 'ง่าย';
    }
  }

  Treatment copyWith({
    int? id,
    String? name,
    String? description,
    int? durationSeconds,
    int? painPointId,
    String? instructions,
    String? imagePath,
    int? difficulty,
  }) {
    return Treatment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      painPointId: painPointId ?? this.painPointId,
      instructions: instructions ?? this.instructions,
      imagePath: imagePath ?? this.imagePath,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  String toString() {
    return 'Treatment{id: $id, name: $name, duration: $durationText}';
  }
}
