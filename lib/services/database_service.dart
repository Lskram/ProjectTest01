import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/user_settings.dart';
import '../models/notification_session.dart';
import '../utils/hive_boxes.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  // ============== PAIN POINTS ==============

  /// เพิ่มข้อมูลเริ่มต้น PainPoints ทั้งหมด
  Future<void> initializePainPoints() async {
    final box = HiveBoxes.painPoints;

    if (box.isEmpty) {
      final painPoints = _getDefaultPainPoints();
      for (final painPoint in painPoints) {
        await box.put(painPoint.id, painPoint);
      }
    }
  }

  /// ดึง PainPoints ทั้งหมด
  List<PainPoint> getAllPainPoints() {
    return HiveBoxes.painPoints.values.toList();
  }

  /// ดึง PainPoints ที่เลือกไว้เท่านั้น
  List<PainPoint> getSelectedPainPoints() {
    return HiveBoxes.painPoints.values
        .where((painPoint) => painPoint.isSelected)
        .toList();
  }

  /// อัปเดต PainPoint
  Future<void> updatePainPoint(PainPoint painPoint) async {
    await HiveBoxes.painPoints.put(painPoint.id, painPoint);
  }

  /// เลือก PainPoints (สูงสุด 3 จุด)
  Future<void> selectPainPoints(List<int> selectedIds) async {
    final box = HiveBoxes.painPoints;

    // Reset all selections first
    for (final painPoint in box.values) {
      if (painPoint.isSelected) {
        await box.put(painPoint.id, painPoint.copyWith(isSelected: false));
      }
    }

    // Set new selections (max 3)
    final idsToSelect = selectedIds.take(3).toList();
    for (final id in idsToSelect) {
      final painPoint = box.get(id);
      if (painPoint != null) {
        await box.put(id, painPoint.copyWith(isSelected: true));
      }
    }
  }

  // ============== TREATMENTS ==============

  /// เพิ่มข้อมูลเริ่มต้น Treatments ทั้งหมด
  Future<void> initializeTreatments() async {
    final box = HiveBoxes.treatments;

    if (box.isEmpty) {
      final treatments = _getDefaultTreatments();
      for (final treatment in treatments) {
        await box.put(treatment.id, treatment);
      }
    }
  }

  /// ดึง Treatments ทั้งหมด
  List<Treatment> getAllTreatments() {
    return HiveBoxes.treatments.values.toList();
  }

  /// ดึง Treatments ของ PainPoint ที่ระบุ
  List<Treatment> getTreatmentsForPainPoint(int painPointId) {
    return HiveBoxes.treatments.values
        .where((treatment) => treatment.painPointId == painPointId)
        .toList();
  }

  /// เพิ่ม Treatment ใหม่
  Future<void> addTreatment(Treatment treatment) async {
    await HiveBoxes.treatments.put(treatment.id, treatment);
  }

  /// อัปเดต Treatment
  Future<void> updateTreatment(Treatment treatment) async {
    await HiveBoxes.treatments.put(treatment.id, treatment);
  }

  /// ลบ Treatment
  Future<void> deleteTreatment(int treatmentId) async {
    await HiveBoxes.treatments.delete(treatmentId);
  }

  // ============== USER SETTINGS ==============

  /// ดึงการตั้งค่าของผู้ใช้
  UserSettings getUserSettings() {
    final box = HiveBoxes.settings;
    return box.get('user_settings') ?? UserSettings();
  }

  /// บันทึกการตั้งค่าของผู้ใช้
  Future<void> saveUserSettings(UserSettings settings) async {
    await HiveBoxes.settings.put('user_settings', settings);
  }

  // ============== NOTIFICATION SESSIONS ==============

  /// บันทึก NotificationSession
  Future<void> saveNotificationSession(NotificationSession session) async {
    await HiveBoxes.sessions.put(session.id, session);
  }

  /// ดึง NotificationSession ตาม ID
  NotificationSession? getNotificationSession(String sessionId) {
    return HiveBoxes.sessions.get(sessionId);
  }

  /// ดึง Sessions ของวันที่ระบุ
  List<NotificationSession> getSessionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return HiveBoxes.sessions.values
        .where((session) =>
            session.scheduledTime.isAfter(startOfDay) &&
            session.scheduledTime.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// ดึง Sessions ของสัปดาห์ที่แล้ว
  List<NotificationSession> getSessionsForLastWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return HiveBoxes.sessions.values
        .where((session) => session.scheduledTime.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// ลบ Sessions เก่า (เก็บไว้แค่ 30 วัน)
  Future<void> cleanupOldSessions() async {
    final box = HiveBoxes.sessions;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final keysToDelete = <String>[];

    for (final session in box.values) {
      if (session.scheduledTime.isBefore(thirtyDaysAgo)) {
        keysToDelete.add(session.id);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  // ============== STATISTICS ==============

  /// สถิติการใช้งานวันนี้
  Map<String, dynamic> getTodayStats() {
    final today = DateTime.now();
    final sessions = getSessionsForDate(today);

    final totalSessions = sessions.length;
    final completedSessions = sessions.where((s) => s.isCompleted).length;
    final skippedSessions = sessions.where((s) => s.isSkipped).length;
    final snoozedSessions =
        sessions.where((s) => s.status == SessionStatus.snoozed).length;

    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'skippedSessions': skippedSessions,
      'snoozedSessions': snoozedSessions,
      'completionRate':
          totalSessions > 0 ? (completedSessions / totalSessions) : 0.0,
    };
  }

  /// สถิติการใช้งานสัปดาห์ที่แล้ว
  Map<String, dynamic> getWeeklyStats() {
    final sessions = getSessionsForLastWeek();

    final totalSessions = sessions.length;
    final completedSessions = sessions.where((s) => s.isCompleted).length;

    // สถิติรายวัน
    final dailyStats = <DateTime, Map<String, int>>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      dailyStats[dateKey] = {'total': 0, 'completed': 0};
    }

    for (final session in sessions) {
      final dateKey = DateTime(
        session.scheduledTime.year,
        session.scheduledTime.month,
        session.scheduledTime.day,
      );

      if (dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey]!['total'] = dailyStats[dateKey]!['total']! + 1;
        if (session.isCompleted) {
          dailyStats[dateKey]!['completed'] =
              dailyStats[dateKey]!['completed']! + 1;
        }
      }
    }

    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'completionRate':
          totalSessions > 0 ? (completedSessions / totalSessions) : 0.0,
      'dailyStats': dailyStats,
    };
  }

  // ============== INITIALIZATION ==============

  /// เริ่มต้นข้อมูลทั้งหมด
  Future<void> initializeAllData() async {
    await initializePainPoints();
    await initializeTreatments();
    await cleanupOldSessions();
  }

  // ============== DEFAULT DATA ==============

  List<PainPoint> _getDefaultPainPoints() {
    return [
      PainPoint(
        id: 1,
        name: 'ศีรษะ',
        description: 'ปวดหัว เมื่อยหัว จากการทำงานหนัก',
        iconName: 'head',
        treatmentIds: [1, 2, 3],
      ),
      PainPoint(
        id: 2,
        name: 'ตา',
        description: 'ตาแห้ง ตาเมื่อย จากการมองจอคอมพิวเตอร์',
        iconName: 'eye',
        treatmentIds: [4, 5, 6],
      ),
      PainPoint(
        id: 3,
        name: 'คอ',
        description: 'ปวดคอ คอแข็ง จากท่านั่งผิด',
        iconName: 'neck',
        treatmentIds: [7, 8],
      ),
      PainPoint(
        id: 4,
        name: 'บ่าและไหล่',
        description: 'ปวดบ่า ไหล่แข็ง จากการนั่งงุ้ม',
        iconName: 'shoulder',
        treatmentIds: [9, 10, 11],
      ),
      PainPoint(
        id: 5,
        name: 'หลังส่วนบน',
        description: 'ปวดหลังบน กล้ามเนื้อตึง',
        iconName: 'back_upper',
        treatmentIds: [12, 13, 14],
      ),
      PainPoint(
        id: 6,
        name: 'หลังส่วนล่าง',
        description: 'ปวดหลังล่าง จากการนั่งนาน',
        iconName: 'back_lower',
        treatmentIds: [15, 16, 17],
      ),
      PainPoint(
        id: 7,
        name: 'แขน/ศอก',
        description: 'ปวดแขน ศอกแข็ง จากการใช้เมาส์',
        iconName: 'arm',
        treatmentIds: [18, 19],
      ),
      PainPoint(
        id: 8,
        name: 'ข้อมือ/มือ/นิ้ว',
        description: 'ปวดข้อมือ นิ้วแข็ง จากการพิมพ์',
        iconName: 'wrist',
        treatmentIds: [20, 21],
      ),
      PainPoint(
        id: 9,
        name: 'ขา',
        description: 'ขาชา เมื่อยขา จากการนั่งนาน',
        iconName: 'leg',
        treatmentIds: [22, 23],
      ),
      PainPoint(
        id: 10,
        name: 'เท้า',
        description: 'ปวดเท้า เมื่อยเท้า จากการยืนนาน',
        iconName: 'foot',
        treatmentIds: [24, 25],
      ),
    ];
  }

  List<Treatment> _getDefaultTreatments() {
    return [
      // ศีรษะ (1-3)
      Treatment(
        id: 1,
        name: 'หายใจลึก',
        description: 'หายใจเข้า-ออกลึกๆ ให้สมอง',
        durationSeconds: 30,
        painPointId: 1,
        instructions: 'นั่งตัวตรง หายใจเข้า-ออกลึกๆ 3 ครั้ง',
        difficulty: 1,
      ),
      Treatment(
        id: 2,
        name: 'กดจุดระหว่างคิ้ว',
        description: 'กดจุด acupressure ลดปวดหัว',
        durationSeconds: 10,
        painPointId: 1,
        instructions: 'ใช้นิ้วชี้กดจุดระหว่างคิ้วเบาๆ 10 วินาที',
        difficulty: 1,
      ),
      Treatment(
        id: 3,
        name: 'นวดขมับ',
        description: 'นวดขมับเพื่อคลายความตึง',
        durationSeconds: 30,
        painPointId: 1,
        instructions: 'นวดเบาๆ ที่ขมับเป็นวงกลมทั้งสองข้าง 30 วินาที',
        difficulty: 1,
      ),

      // ตา (4-6)
      Treatment(
        id: 4,
        name: 'กระพริบตาแน่น',
        description: 'บริหารกล้ามเนื้อตา',
        durationSeconds: 25,
        painPointId: 2,
        instructions: 'หลับตาแน่น 5 วิ แล้วลืม ทำซ้ำ 5 รอบ',
        difficulty: 1,
      ),
      Treatment(
        id: 5,
        name: 'มองไกล 20 ฟุต',
        description: 'กฎ 20-20-20 สำหรับสายตา',
        durationSeconds: 20,
        painPointId: 2,
        instructions: 'มองไกลออกไป 20 ฟุต นาน 20 วินาที',
        difficulty: 1,
      ),
      Treatment(
        id: 6,
        name: 'กลิ้งลูกตา',
        description: 'บริหารกล้ามเนื้อรอบดวงตา',
        durationSeconds: 30,
        painPointId: 2,
        instructions: 'กลิ้งลูกตาบน-ล่าง-ซ้าย-ขวา ช้าๆ',
        difficulty: 1,
      ),

      // คอ (7-8)
      Treatment(
        id: 7,
        name: 'หันคอ 4 ทิศ',
        description: 'บริหารคอทุกทิศทาง',
        durationSeconds: 40,
        painPointId: 3,
        instructions: 'ก้มคางแตะอก > เงยหน้า > หันซ้าย > หันขวา ช้าๆ',
        difficulty: 1,
      ),
      Treatment(
        id: 8,
        name: 'เอียงคอกดเบา',
        description: 'ยืดกล้ามเนื้อข้างคอ',
        durationSeconds: 20,
        painPointId: 3,
        instructions: 'เอียงคอไปข้างหนึ่ง ใช้มือกดเบาๆ ค้าง 10 วิ ทำสลับ',
        difficulty: 1,
      ),

      // บ่าและไหล่ (9-11)
      Treatment(
        id: 9,
        name: 'ยกไหล่ขึ้น-ลง',
        description: 'คลายความตึงไหล่',
        durationSeconds: 30,
        painPointId: 4,
        instructions: 'ยกไหล่ทั้งสองขึ้นให้สูงสุด แล้วปล่อยลง ทำ 10 ครั้ง',
        difficulty: 1,
      ),
      Treatment(
        id: 10,
        name: 'หมุนไหล่',
        description: 'บริหารข้อไหล่',
        durationSeconds: 40,
        painPointId: 4,
        instructions: 'หมุนไหล่ไปข้างหน้า 10 รอบ แล้วย้อนกลับ',
        difficulty: 1,
      ),
      Treatment(
        id: 11,
        name: 'ดึงแขนข้ามอก',
        description: 'ยืดกล้ามเนื้อไหล่',
        durationSeconds: 20,
        painPointId: 4,
        instructions: 'ดึงแขนข้ามหน้าอก ใช้มืออีกข้างกอด ค้าง 10 วิ สลับ',
        difficulty: 1,
      ),

      // หลังส่วนบน (12-14)
      Treatment(
        id: 12,
        name: 'ประสานมือยืด',
        description: 'ยืดกล้ามเนื้อหลัง',
        durationSeconds: 30,
        painPointId: 5,
        instructions: 'ประสานมือยืดไปหน้า โค้งหลัง รู้สึกยืด',
        difficulty: 1,
      ),
      Treatment(
        id: 13,
        name: 'บิดตัวซ้าย-ขวา',
        description: 'บริหารกระดูกสันหลัง',
        durationSeconds: 30,
        painPointId: 5,
        instructions: 'นั่งตัวตรง บิดตัวไปซ้าย-ขวา ช้าๆ',
        difficulty: 1,
      ),
      Treatment(
        id: 14,
        name: 'ดันไหล่เข้าหา',
        description: 'เปิดหน้าอก ยืดหลัง',
        durationSeconds: 15,
        painPointId: 5,
        instructions: 'ดันไหล่ทั้งสองเข้าหากัน เปิดหน้าอก',
        difficulty: 1,
      ),

      // หลังส่วนล่าง (15-17)
      Treatment(
        id: 15,
        name: 'โค้งหลังเบา',
        description: 'ยืดกล้ามเนื้อหลังล่าง',
        durationSeconds: 20,
        painPointId: 6,
        instructions: 'นั่งขอบเก้าอี้ โค้งหลังเบาๆ ไปข้างหน้า',
        difficulty: 1,
      ),
      Treatment(
        id: 16,
        name: 'บิดเอวนั่ง',
        description: 'บริหารเอวและหลังล่าง',
        durationSeconds: 30,
        painPointId: 6,
        instructions: 'นั่งบิดเอวซ้าย-ขวา ใช้มือจับที่เก้าอี้',
        difficulty: 2,
      ),
      Treatment(
        id: 17,
        name: 'ยืนเหยียดตัว',
        description: 'เหยียดร่างกายทั้งหมด',
        durationSeconds: 15,
        painPointId: 6,
        instructions: 'ยืนยกมือขึ้นสูง เหยียดตัวให้ยาว',
        difficulty: 1,
      ),

      // แขน/ศอก (18-19)
      Treatment(
        id: 18,
        name: 'งอ-เหยียดแขน',
        description: 'บริหารข้อศอก',
        durationSeconds: 30,
        painPointId: 7,
        instructions: 'งอ-เหยียดแขนช้าๆ 10 ครั้ง',
        difficulty: 1,
      ),
      Treatment(
        id: 19,
        name: 'หมุนแขนเล็ก',
        description: 'คลายความตึงแขน',
        durationSeconds: 20,
        painPointId: 7,
        instructions: 'หมุนแขนเป็นวงกลมเล็กๆ 10 รอบ',
        difficulty: 1,
      ),

      // ข้อมือ/มือ/นิ้ว (20-21)
      Treatment(
        id: 20,
        name: 'งอ-เหยียดข้อมือ',
        description: 'บริหารข้อมือ',
        durationSeconds: 30,
        painPointId: 8,
        instructions: 'งอ-เหยียดข้อมือขึ้น-ลง 10 ครั้ง',
        difficulty: 1,
      ),
      Treatment(
        id: 21,
        name: 'กำมือ-คลายมือ',
        description: 'บริหารกล้ามเนื้อมือ',
        durationSeconds: 20,
        painPointId: 8,
        instructions: 'กำมือแน่น 5 วิ แล้วคลาย ทำซ้ำ 5 ครั้ง',
        difficulty: 1,
      ),

      // ขา (22-23)
      Treatment(
        id: 22,
        name: 'ยกเข่าสูง',
        description: 'กระตุ้นการไหลเวียนขา',
        durationSeconds: 30,
        painPointId: 9,
        instructions: 'ยกเข่าสลับซ้าย-ขวา สูงๆ 15 ครั้ง',
        difficulty: 2,
      ),
      Treatment(
        id: 23,
        name: 'เหยียดขาตรง',
        description: 'ยืดกล้ามเนื้อขา',
        durationSeconds: 20,
        painPointId: 9,
        instructions: 'นั่งเหยียดขาตรง ค้าง 10 วิ สลับขา',
        difficulty: 1,
      ),

      // เท้า (24-25)
      Treatment(
        id: 24,
        name: 'หมุนข้อเท้า',
        description: 'บริหารข้อเท้า',
        durationSeconds: 30,
        painPointId: 10,
        instructions: 'หมุนข้อเท้าซ้าย-ขวา 10 รอบ สลับเท้า',
        difficulty: 1,
      ),
      Treatment(
        id: 25,
        name: 'งอ-เหยียดนิ้วเท้า',
        description: 'คลายกล้ามเนื้อเท้า',
        durationSeconds: 20,
        painPointId: 10,
        instructions: 'งอ-เหยียดนิ้วเท้าแน่นๆ 10 ครั้ง',
        difficulty: 1,
      ),
    ];
  }
}
