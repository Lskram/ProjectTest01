import 'dart:math';
import '../models/treatment.dart'; // ลบ pain_point.dart ที่ไม่ได้ใช้
import 'database_service.dart';

class RandomService {
  static RandomService? _instance;
  static RandomService get instance => _instance ??= RandomService._();
  RandomService._();

  final Random _random = Random();

  /// สุ่มเลือกจุดที่ปวดและท่าออกกำลังกาย
  Map<String, dynamic>? selectRandomTreatments(List<int> selectedPainPointIds) {
    if (selectedPainPointIds.isEmpty) return null;

    // สุ่มเลือกจุดที่ปวด 1 จุด
    final randomPainPointId =
        selectedPainPointIds[_random.nextInt(selectedPainPointIds.length)];

    // หาจุดที่ปวดนั้น
    final painPoint = DatabaseService.instance
        .getAllPainPoints()
        .firstWhere((p) => p.id == randomPainPointId);

    // หา treatments ของจุดนั้น
    final availableTreatments =
        DatabaseService.instance.getTreatmentsForPainPoint(randomPainPointId);

    if (availableTreatments.isEmpty) return null;

    // สุ่มเลือก treatments 2 ท่า (หรือทั้งหมดถ้ามีน้อยกว่า 2)
    final selectedTreatments = _selectRandomTreatments(
        availableTreatments, min(2, availableTreatments.length));

    return {
      'painPoint': painPoint,
      'treatments': selectedTreatments,
    };
  }

  /// สุ่มเลือก treatments จำนวนที่กำหนด
  List<Treatment> _selectRandomTreatments(
      List<Treatment> treatments, int count) {
    if (treatments.length <= count) return treatments;

    // สุ่มโดยไม่ซ้ำ
    final shuffled = List<Treatment>.from(treatments);
    shuffled.shuffle(_random);

    return shuffled.take(count).toList();
  }

  /// สุ่มเลือกจุดที่ปวดสำหรับสถิติ (ใช้น้ำหนักตามความบ่อย)
  int? selectWeightedPainPoint(List<int> selectedPainPointIds) {
    if (selectedPainPointIds.isEmpty) return null;

    // ดูสถิติการใช้งานล่าสุด
    final sessions = DatabaseService.instance
        .getSessionsForLastWeek(); // ลบ weeklyStats ที่ไม่ได้ใช้

    // นับความบ่อยของแต่ละจุด
    final painPointCounts = <int, int>{};
    for (final id in selectedPainPointIds) {
      painPointCounts[id] = 0;
    }

    for (final session in sessions) {
      if (painPointCounts.containsKey(session.painPointId)) {
        painPointCounts[session.painPointId] =
            painPointCounts[session.painPointId]! + 1;
      }
    }

    // สร้างน้ำหนักแบบ inverse (จุดที่ใช้น้อย จะได้โอกาสมากขึ้น)
    final maxCount = painPointCounts.values.isEmpty
        ? 0
        : painPointCounts.values.reduce((a, b) => a > b ? a : b);

    final weights = <int>[];

    for (final entry in painPointCounts.entries) {
      final weight = maxCount - entry.value + 1; // +1 เพื่อไม่ให้เป็น 0
      for (int i = 0; i < weight; i++) {
        weights.add(entry.key);
      }
    }

    if (weights.isEmpty) {
      // ถ้าไม่มีสถิติ ให้สุ่มปกติ
      return selectedPainPointIds[_random.nextInt(selectedPainPointIds.length)];
    }

    return weights[_random.nextInt(weights.length)];
  }

  /// สุ่มเลือก treatment โดยพิจารณาความยาก
  List<Treatment> selectBalancedTreatments(
      List<Treatment> treatments, int count,
      {int? preferredDifficulty}) {
    if (treatments.length <= count) return treatments;

    // แยกตามระดับความยาก
    final easyTreatments = treatments.where((t) => t.difficulty == 1).toList();
    final mediumTreatments =
        treatments.where((t) => t.difficulty == 2).toList();
    final hardTreatments = treatments.where((t) => t.difficulty == 3).toList();

    final selected = <Treatment>[];

    if (preferredDifficulty != null) {
      // เลือกตามระดับที่ต้องการก่อน
      List<Treatment> preferred;
      switch (preferredDifficulty) {
        case 1:
          preferred = easyTreatments;
          break;
        case 2:
          preferred = mediumTreatments;
          break;
        case 3:
          preferred = hardTreatments;
          break;
        default:
          preferred = easyTreatments;
      }

      if (preferred.isNotEmpty) {
        preferred.shuffle(_random);
        selected.addAll(preferred.take(min(count, preferred.length)));
      }
    }

    // เติมที่เหลือด้วยการสุ่มปกติ
    if (selected.length < count) {
      final remaining = treatments.where((t) => !selected.contains(t)).toList();
      remaining.shuffle(_random);
      selected.addAll(remaining.take(count - selected.length));
    }

    return selected;
  }

  /// สุ่มเลือกโดยพิจารณาเวลา (ช่วงเช้าใช้ท่าง่าย ช่วงบ่ายใช้ท่าหนักขึ้น)
  List<Treatment> selectTimeBasedTreatments(
      List<Treatment> treatments, int count) {
    if (treatments.isEmpty) return [];

    final now = DateTime.now();
    int preferredDifficulty;

    if (now.hour < 10) {
      // เช้า: ท่าง่าย
      preferredDifficulty = 1;
    } else if (now.hour < 15) {
      // กลางวัน: ท่าปานกลาง
      preferredDifficulty = 2;
    } else {
      // บ่าย: ท่าหนักขึ้นได้
      preferredDifficulty = _random.nextBool() ? 2 : 3;
    }

    return selectBalancedTreatments(treatments, count,
        preferredDifficulty: preferredDifficulty);
  }

  /// สุ่มช่วงเวลาพักสำหรับการทดสอบ
  List<int> generateRandomSnoozeOptions() {
    final baseOptions = [5, 10, 15, 20, 30];
    baseOptions.shuffle(_random);
    return baseOptions.take(3).toList()..sort();
  }

  /// สุ่มข้อความกำลังใจ
  String getRandomEncouragementMessage() {
    final messages = [
      'เยี่ยม! มาดูแลสุขภาพกันเถอะ 💪',
      'ถึงเวลาพักแล้ว ลุกขยับกันหน่อย! 😊',
      'มาออกกำลังกายเบาๆ กัน ✨',
      'ร่างกายต้องการการดูแลแล้วนะ 🌟',
      'แค่นิดเดียวแล้ว จะรู้สึกดีขึ้น! 🎯',
      'มาทำให้สมองและร่างกายสดชื่น 🚀',
      'เวลาดูแลตัวเองแล้ว! 💚',
      'ลุกขึ้นมาเคลื่อนไหวกันเถอะ 🏃‍♀️',
    ];

    return messages[_random.nextInt(messages.length)];
  }
}
