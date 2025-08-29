import 'package:hive/hive.dart';

part 'pain_point.g.dart';

@HiveType(typeId: 0)
class PainPoint extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconName;

  @HiveField(4)
  final bool isSelected;

  @HiveField(5)
  final List<int> treatmentIds;

  PainPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.isSelected = false,
    required this.treatmentIds,
  });

  // Copy with method สำหรับอัปเดตข้อมูล
  PainPoint copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    bool? isSelected,
    List<int>? treatmentIds,
  }) {
    return PainPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isSelected: isSelected ?? this.isSelected,
      treatmentIds: treatmentIds ?? this.treatmentIds,
    );
  }

  @override
  String toString() {
    return 'PainPoint{id: $id, name: $name, isSelected: $isSelected}';
  }
}
