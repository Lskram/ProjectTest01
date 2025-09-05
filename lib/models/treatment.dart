import 'package:hive/hive.dart';
@HiveType(typeId: 3)
class Treatment extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nameTh;

  @HiveField(2)
  String nameEn;

  @HiveField(3)
  String description;

  @HiveField(4)
  List<String> instructions;

  @HiveField(5)
  int painPointId;

  @HiveField(6)
  int duration; // in seconds

  @HiveField(7)
  int difficulty; // 1-5 scale

  // NEW ENHANCED FIELDS
  @HiveField(8)
  String? imageAssetPath;

  @HiveField(9)
  List<String>? videoSteps; // Step-by-step descriptions

  @HiveField(10)
  String? warnings; // Safety warnings

  @HiveField(11)
  List<String>? benefits; // Health benefits

  @HiveField(12)
  int repetitions; // How many times to repeat

  @HiveField(13)
  String category; // "stretch", "strengthen", "relax"

  @HiveField(14)
  bool isActive;

  @HiveField(15)
  int usageCount; // Track how often used

  Treatment({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.description,
    required this.instructions,
    required this.painPointId,
    this.duration = 30,
    this.difficulty = 1,
    this.imageAssetPath,
    this.videoSteps,
    this.warnings,
    this.benefits,
    this.repetitions = 1,
    this.category = 'stretch',
    this.isActive = true,
    this.usageCount = 0,
  });

  // Helper methods
  String get durationText {
    if (duration < 60) {
      return '${duration} วินาที';
    } else {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      if (seconds == 0) {
        return '${minutes} นาที';
      } else {
        return '${minutes} นาที ${seconds} วินาที';
      }
    }
  }

  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'ง่ายมาก';
      case 2:
        return 'ง่าย';
      case 3:
        return 'ปานกลาง';
      case 4:
        return 'ยาก';
      case 5:
        return 'ยากมาก';
      default:
        return 'ปานกลาง';
    }
  }

  String get categoryText {
    switch (category) {
      case 'stretch':
        return 'ยืดเหยียด';
      case 'strengthen':
        return 'เสริมสร้างกล้ามเนื้อ';
      case 'relax':
        return 'ผ่อนคลาย';
      default:
        return 'ยืดเหยียด';
    }
  }

  // Increment usage count
  void incrementUsage() {
    usageCount++;
    save(); // Save to Hive
  }

  // Copy with method
  Treatment copyWith({
    int? id,
    String? nameTh,
    String? nameEn,
    String? description,
    List<String>? instructions,
    int? painPointId,
    int? duration,
    int? difficulty,
    String? imageAssetPath,
    List<String>? videoSteps,
    String? warnings,
    List<String>? benefits,
    int? repetitions,
    String? category,
    bool? isActive,
    int? usageCount,
  }) {
    return Treatment(
      id: id ?? this.id,
      nameTh: nameTh ?? this.nameTh,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      painPointId: painPointId ?? this.painPointId,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      videoSteps: videoSteps ?? this.videoSteps,
      warnings: warnings ?? this.warnings,
      benefits: benefits ?? this.benefits,
      repetitions: repetitions ?? this.repetitions,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  String toString() {
    return 'Treatment(id: $id, name: $nameTh, painPoint: $painPointId, duration: ${durationText})';
  }

  // Factory method for creating treatments with common patterns
  factory Treatment.createStretch({
    required int id,
    required String nameTh,
    required String nameEn,
    required String description,
    required List<String> instructions,
    required int painPointId,
    int duration = 30,
    int difficulty = 1,
    String? warnings,
    List<String>? benefits,
    int repetitions = 3,
  }) {
    return Treatment(
      id: id,
      nameTh: nameTh,
      nameEn: nameEn,
      description: description,
      instructions: instructions,
      painPointId: painPointId,
      duration: duration,
      difficulty: difficulty,
      warnings: warnings,
      benefits: benefits,
      repetitions: repetitions,
      category: 'stretch',
    );
  }

  factory Treatment.createStrengthening({
    required int id,
    required String nameTh,
    required String nameEn,
    required String description,
    required List<String> instructions,
    required int painPointId,
    int duration = 45,
    int difficulty = 3,
    String? warnings,
    List<String>? benefits,
    int repetitions = 10,
  }) {
    return Treatment(
      id: id,
      nameTh: nameTh,
      nameEn: nameEn,
      description: description,
      instructions: instructions,
      painPointId: painPointId,
      duration: duration,
      difficulty: difficulty,
      warnings: warnings,
      benefits: benefits,
      repetitions: repetitions,
      category: 'strengthen',
    );
  }

  factory Treatment.createRelaxation({
    required int id,
    required String nameTh,
    required String nameEn,
    required String description,
    required List<String> instructions,
    required int painPointId,
    int duration = 60,
    int difficulty = 1,
    String? warnings,
    List<String>? benefits,
    int repetitions = 1,
  }) {
    return Treatment(
      id: id,
      nameTh: nameTh,
      nameEn: nameEn,
      description: description,
      instructions: instructions,
      painPointId: painPointId,
      duration: duration,
      difficulty: difficulty,
      warnings: warnings,
      benefits: benefits,
      repetitions: repetitions,
      category: 'relax',
    );
  }
}
