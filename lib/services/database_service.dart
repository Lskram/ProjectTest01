import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/user_settings.dart';
import '../models/notification_session.dart';
import '../utils/hive_boxes.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  bool _isInitialized = false;

  /// Initialize database (main isolate)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('💾 Initializing DatabaseService...');

      await HiveBoxes.initHive();
      await _seedInitialData();

      _isInitialized = true;
      debugPrint('✅ DatabaseService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing DatabaseService: $e');
      rethrow;
    }
  }

  /// Initialize database in isolate (background)
  Future<void> initializeInIsolate() async {
    try {
      debugPrint('💾 Initializing DatabaseService in isolate...');

      await HiveBoxes.initHive();
      _isInitialized = true;

      debugPrint('✅ DatabaseService initialized in isolate');
    } catch (e) {
      debugPrint('❌ Error initializing DatabaseService in isolate: $e');
      rethrow;
    }
  }

  /// Seed initial data
  Future<void> _seedInitialData() async {
    try {
      await _seedPainPoints();
      await _seedTreatments();
      debugPrint('✅ Initial data seeded');
    } catch (e) {
      debugPrint('❌ Error seeding initial data: $e');
    }
  }

  /// Seed pain points
  Future<void> _seedPainPoints() async {
    final box = await HiveBoxes.painPointsBox;

    if (box.isNotEmpty) return; // Already seeded

    final painPoints = [
      PainPoint(
          id: 1,
          nameTh: 'ศีรษะ',
          nameEn: 'Head',
          description: 'อาการปวดหัว ตึงเครียดบริเวณศีรษะ'),
      PainPoint(
          id: 2,
          nameTh: 'ตา',
          nameEn: 'Eyes',
          description: 'อาการตาเหนื่อย แสบตา จากการจ้องหน้าจอ'),
      PainPoint(
          id: 3,
          nameTh: 'คอ',
          nameEn: 'Neck',
          description: 'อาการคอเก็ง ปวดต้นคอ จากท่านั่งผิด'),
      PainPoint(
          id: 4,
          nameTh: 'บ่าและไหล่',
          nameEn: 'Shoulders',
          description: 'อาการปวดบ่า ไหล่แข็ง จากการนั่งเป็นเวลานาน'),
      PainPoint(
          id: 5,
          nameTh: 'หลังส่วนบน',
          nameEn: 'Upper Back',
          description: 'อาการปวดหลังส่วนบน กล้ามเนื้อตึง'),
      PainPoint(
          id: 6,
          nameTh: 'หลังส่วนล่าง',
          nameEn: 'Lower Back',
          description: 'อาการปวดหลังล่าง จากท่านั่งไม่ถูกต้อง'),
      PainPoint(
          id: 7,
          nameTh: 'แขน/ศอก',
          nameEn: 'Arms/Elbows',
          description: 'อาการปวดแขน ศอก จากการใช้คอมพิวเตอร์'),
      PainPoint(
          id: 8,
          nameTh: 'ข้อมือ/มือ/นิ้ว',
          nameEn: 'Wrists/Hands/Fingers',
          description: 'อาการปวดข้อมือ มือ นิ้ว จากการพิมพ์'),
      PainPoint(
          id: 9,
          nameTh: 'ขา',
          nameEn: 'Legs',
          description: 'อาการปวดขา เมื่อยขา จากการนั่งเป็นเวลานาน'),
      PainPoint(
          id: 10,
          nameTh: 'เท้า',
          nameEn: 'Feet',
          description: 'อาการปวดเท้า เมื่อยเท้า จากการยืนหรือนั่งนาน'),
    ];

    for (final painPoint in painPoints) {
      await box.put(painPoint.id, painPoint);
    }

    debugPrint('✅ Pain points seeded: ${painPoints.length} items');
  }

  /// Seed treatments (25+ exercises)
  Future<void> _seedTreatments() async {
    final box = await HiveBoxes.treatmentsBox;

    if (box.isNotEmpty) return; // Already seeded

    final treatments = [
      // HEAD EXERCISES (ID 1)
      Treatment.createRelaxation(
        id: 1,
        nameTh: 'นวดหนังศีรษะ',
        nameEn: 'Scalp Massage',
        description: 'นวดหนังศีรษะเบาๆ เพื่อกระตุ้นการไหลเวียนเลือด',
        instructions: [
          'ใช้ปลายนิ้วนวดหนังศีรษะเป็นวงกลม',
          'เริ่มจากหน้าผากไปยังท้ายทอย',
          'กดเบาๆ และนวดช้าๆ',
        ],
        painPointId: 1,
        benefits: ['ลดความเครียด', 'กระตุ้นการไหลเวียนเลือด', 'ลดอาการปวดหัว'],
      ),

      Treatment.createStretch(
        id: 2,
        nameTh: 'หมุนคอช้าๆ',
        nameEn: 'Slow Neck Rolls',
        description: 'หมุนคอช้าๆ เพื่อคลายความตึงเครียด',
        instructions: [
          'นั่งตรง ผ่อนคลายไหล่',
          'หมุนหัวช้าๆ ตามเข็มนาฬิกา 5 รอบ',
          'หมุนทวนเข็มนาฬิกา 5 รอบ',
        ],
        painPointId: 1,
        benefits: ['ลดความตึงเครียด', 'เพิ่มความยืดหยุ่น'],
        warnings: 'หมุนช้าๆ ไม่ควรหมุนเร็วจนเกินไป',
      ),

      // EYE EXERCISES (ID 2)
      Treatment.createRelaxation(
        id: 3,
        nameTh: 'พักสายตา 20-20-20',
        nameEn: '20-20-20 Eye Rest',
        description:
            'หลักการพักสายตา ทุก 20 นาที มอง 20 ฟุต เป็นเวลา 20 วินาที',
        instructions: [
          'หยุดมองหน้าจอ',
          'มองไปที่จุดไกลๆ (20 ฟุต หรือ 6 เมตร)',
          'จ้องมอง 20 วินาที',
        ],
        painPointId: 2,
        duration: 20,
        benefits: ['ลดความเมื่อยล้าของตา', 'ป้องกันสายตาเสื่อม'],
      ),

      Treatment.createStretch(
        id: 4,
        nameTh: 'ยืดกล้ามเนื้อตา',
        nameEn: 'Eye Muscle Stretching',
        description: 'ขยับลูกตาไปในทิศทางต่างๆ',
        instructions: [
          'มองขึ้น-ล่าง 5 ครั้ง',
          'มองซ้าย-ขวา 5 ครั้ง',
          'หมุนลูกตาตามเข็มนาฬิกา 5 รอบ',
          'หลับตาพัก 10 วินาที',
        ],
        painPointId: 2,
        repetitions: 3,
      ),

      // NECK EXERCISES (ID 3)
      Treatment.createStretch(
        id: 5,
        nameTh: 'ยืดคอด้านข้าง',
        nameEn: 'Lateral Neck Stretch',
        description: 'ยืดกล้ามเนื้อคอด้านข้าง',
        instructions: [
          'เอียงหัวไปทางขวา',
          'ใช้มือขวาดึงหัวเบาๆ',
          'ค้างไว้ 15 วินาที',
          'สลับด้าน',
        ],
        painPointId: 3,
        benefits: ['ยืดกล้ามเนื้อคอ', 'ลดความเก็ง'],
        warnings: 'ดึงเบาๆ ไม่ควรใช้แรงมาก',
      ),

      Treatment.createStretch(
        id: 6,
        nameTh: 'ยืดคอด้านหน้า-หลัง',
        nameEn: 'Forward-Backward Neck Stretch',
        description: 'ยืดกล้ามเนื้อคอด้านหน้าและหลัง',
        instructions: [
          'ก้มหัวลง แตะคางกับอก',
          'ค้างไว้ 10 วินาที',
          'เงยหน้าขึ้นเบาๆ',
          'ค้างไว้ 10 วินาที',
        ],
        painPointId: 3,
        repetitions: 5,
      ),

      // SHOULDER EXERCISES (ID 4)
      Treatment.createStretch(
        id: 7,
        nameTh: 'ยกไหล่ขึ้น-ลง',
        nameEn: 'Shoulder Shrugs',
        description: 'ยกไหล่ขึ้นลงเพื่อคลายความตึงเครียด',
        instructions: [
          'ยกไหล่ทั้งสองขึ้นสู่หู',
          'ค้างไว้ 3 วินาที',
          'ปล่อยลงช้าๆ',
          'ทำ 10 ครั้ง',
        ],
        painPointId: 4,
        repetitions: 10,
        benefits: ['คลายกล้ามเนื้อไหล่', 'ลดความตึงเครียด'],
      ),

      Treatment.createStretch(
        id: 8,
        nameTh: 'หมุนไหล่',
        nameEn: 'Shoulder Rolls',
        description: 'หมุนไหล่เพื่อเพิ่มความยืดหยุ่น',
        instructions: [
          'หมุนไหล่ไปข้างหน้า 10 รอบ',
          'หมุนไปข้างหลัง 10 รอบ',
          'หมุนช้าๆ และเต็มวงกลม',
        ],
        painPointId: 4,
        repetitions: 20,
      ),

      Treatment.createStretch(
        id: 9,
        nameTh: 'ยืดกล้ามเนื้อไหล่',
        nameEn: 'Cross-Body Shoulder Stretch',
        description: 'ยืดไหล่ข้ามตัว',
        instructions: [
          'เหยียดแขนขวาข้ามหน้าอก',
          'ใช้แขนซ้ายกอดดึงเข้าหาตัว',
          'ค้างไว้ 15 วินาที',
          'สลับด้าน',
        ],
        painPointId: 4,
        duration: 30,
      ),

      // UPPER BACK EXERCISES (ID 5)
      Treatment.createStretch(
        id: 10,
        nameTh: 'ยืดหลังส่วนบน',
        nameEn: 'Upper Back Stretch',
        description: 'ยืดกล้ามเนื้อหลังส่วนบน',
        instructions: [
          'ยกแขนทั้งสองขึ้น',
          'จับมือไว้และดันออกไปข้างหน้า',
          'โค้งหลังเล็กน้อย',
          'ค้างไว้ 20 วินาที',
        ],
        painPointId: 5,
        benefits: ['ยืดกล้ามเนื้อหลังบน', 'ลดความตึงเครียด'],
      ),

      Treatment.createStretch(
        id: 11,
        nameTh: 'บิดตัว',
        nameEn: 'Seated Spinal Twist',
        description: 'บิดลำตัวขณะนั่ง',
        instructions: [
          'นั่งตรง เท้าแนบพื้น',
          'วางมือซ้ายบนเข่าขวา',
          'บิดตัวไปทางขวาเบาๆ',
          'ค้างไว้ 15 วินาที แล้วสลับด้าน',
        ],
        painPointId: 5,
        repetitions: 4,
      ),

      // LOWER BACK EXERCISES (ID 6)
      Treatment.createStretch(
        id: 12,
        nameTh: 'ยืดหลังโค้ง',
        nameEn: 'Cat-Cow Stretch (Seated)',
        description: 'โค้งหลังไป-มาขณะนั่ง',
        instructions: [
          'นั่งตรง มือวางบนต้นขา',
          'โค้งหลังไปข้างหน้า (วัว)',
          'งอหลังขึ้น (แมว)',
          'สลับไป-มา 10 ครั้ง',
        ],
        painPointId: 6,
        repetitions: 10,
        benefits: ['เพิ่มความยืดหยุ่นกระดูกสันหลัง'],
      ),

      Treatment.createStretch(
        id: 13,
        nameTh: 'กอดเข่าเข้าอก',
        nameEn: 'Knee to Chest (Seated)',
        description: 'กอดเข่าเข้าอกขณะนั่ง',
        instructions: [
          'นั่งตรง',
          'ยกเข่าขวาขึ้น',
          'กอดเข้าอกเบาๆ',
          'ค้างไว้ 10 วินาที แล้วสลับขา',
        ],
        painPointId: 6,
        repetitions: 6,
      ),

      // ARM/ELBOW EXERCISES (ID 7)
      Treatment.createStretch(
        id: 14,
        nameTh: 'ยืดกล้ามเนื้อแขน',
        nameEn: 'Triceps Stretch',
        description: 'ยืดกล้ามเนื้อด้านหลังแขน',
        instructions: [
          'ยกแขนขวาขึ้น',
          'งอศอกให้มือไปแตะหลัง',
          'ใช้มือซ้ายดันศอกเบาๆ',
          'ค้างไว้ 15 วินาที แล้วสลับแขน',
        ],
        painPointId: 7,
        benefits: ['ยืดกล้ามเนื้อแขน', 'เพิ่มความยืดหยุ่น'],
      ),

      Treatment.createStretch(
        id: 15,
        nameTh: 'ยืดข้อศอก',
        nameEn: 'Elbow Extension',
        description: 'เหยียดและงอข้อศอก',
        instructions: [
          'เหยียดแขนตรงไปข้างหน้า',
          'งอศอกขึ้น-ลง',
          'ทำช้าๆ และเต็มที่',
          'ทำ 15 ครั้ง',
        ],
        painPointId: 7,
        repetitions: 15,
      ),

      // WRIST/HAND EXERCISES (ID 8)
      Treatment.createStretch(
        id: 16,
        nameTh: 'ยืดข้อมือ',
        nameEn: 'Wrist Stretch',
        description: 'ยืดกล้ามเนื้อข้อมือ',
        instructions: [
          'เหยียดแขนไปข้างหน้า',
          'งอข้อมือขึ้น ใช้มืออีกข้างดันเบาๆ',
          'ค้างไว้ 10 วินาที',
          'งอข้อมือลง ใช้มืออีกข้างดันเบาๆ',
          'สลับมือ',
        ],
        painPointId: 8,
        repetitions: 4,
        warnings: 'ดันเบาๆ ไม่ควรใช้แรงมาก',
      ),

      Treatment.createStretch(
        id: 17,
        nameTh: 'หมุนข้อมือ',
        nameEn: 'Wrist Circles',
        description: 'หมุนข้อมือเพื่อเพิ่มความยืดหยุ่น',
        instructions: [
          'เหยียดแขนไปข้างหน้า',
          'หมุนข้อมือตามเข็มนาฬิกา 10 รอบ',
          'หมุนทวนเข็มนาฬิกา 10 รอบ',
          'สลับมือ',
        ],
        painPointId: 8,
        repetitions: 20,
      ),

      Treatment.createStrengthening(
        id: 18,
        nameTh: 'บีบมือ',
        nameEn: 'Hand Squeeze',
        description: 'บีบมือเพื่อแข็งแรงกล้ามเนื้อ',
        instructions: [
          'บีบมือแน่น',
          'ค้างไว้ 5 วินาที',
          'คลายมือ',
          'ทำ 10 ครั้ง',
        ],
        painPointId: 8,
        repetitions: 10,
      ),

      // LEG EXERCISES (ID 9)
      Treatment.createStretch(
        id: 19,
        nameTh: 'ยืดกล้ามเนื้อหน้าขา',
        nameEn: 'Quadriceps Stretch (Seated)',
        description: 'ยืดกล้ามเนื้อหน้าขาขณะนั่ง',
        instructions: [
          'นั่งขอบเก้าอี้',
          'เหยียดขาขวาตรง',
          'งอเท้าขึ้น',
          'ค้างไว้ 15 วินาที แล้วสลับขา',
        ],
        painPointId: 9,
        benefits: ['ยืดกล้ามเนื้อขา', 'กระตุ้นการไหลเวียน'],
      ),

      Treatment.createStretch(
        id: 20,
        nameTh: 'ยกขาสลับ',
        nameEn: 'Alternating Leg Lifts',
        description: 'ยกขาสลับเพื่อกระตุ้นการไหลเวียน',
        instructions: [
          'นั่งตรง',
          'ยกขาขวาขึ้น',
          'ค้างไว้ 3 วินาที',
          'วางลง แล้วสลับขา',
          'ทำ 10 ครั้งต่อข้าง',
        ],
        painPointId: 9,
        repetitions: 20,
      ),

      // FEET EXERCISES (ID 10)
      Treatment.createStretch(
        id: 21,
        nameTh: 'ยืดข้อเท้า',
        nameEn: 'Ankle Stretch',
        description: 'ยืดกล้ามเนื้อข้อเท้า',
        instructions: [
          'ยกขาขวาขึ้นเล็กน้อย',
          'งอเท้าขึ้น-ลง',
          'ทำ 15 ครั้ง',
          'สลับเท้า',
        ],
        painPointId: 10,
        repetitions: 30,
      ),

      Treatment.createStretch(
        id: 22,
        nameTh: 'หมุนข้อเท้า',
        nameEn: 'Ankle Circles',
        description: 'หมุนข้อเท้าเพื่อเพิ่มความยืดหยุ่น',
        instructions: [
          'ยกขาขึ้นเล็กน้อย',
          'หมุนข้อเท้าตามเข็มนาฬิกา 10 รอบ',
          'หมุนทวนเข็มนาฬิกา 10 รอบ',
          'สลับเท้า',
        ],
        painPointId: 10,
        repetitions: 40,
      ),

      // GENERAL EXERCISES (Multiple pain points)
      Treatment.createRelaxation(
        id: 23,
        nameTh: 'หายใจลึก',
        nameEn: 'Deep Breathing',
        description: 'หายใจลึกเพื่อผ่อนคลาย',
        instructions: [
          'นั่งตรง ตาเบาๆ',
          'หายใจเข้าทางจมูก 4 วินาที',
          'กลั้นหายใจ 4 วินาที',
          'หายใจออกทางปาก 6 วินาที',
          'ทำ 5 รอบ',
        ],
        painPointId: 1, // Head - but good for all
        duration: 60,
        benefits: ['ลดความเครียด', 'ผ่อนคลายจิตใจ', 'เพิ่มออกซิเจน'],
      ),

      Treatment.createStretch(
        id: 24,
        nameTh: 'ยืดแขน-ขา',
        nameEn: 'Full Body Stretch',
        description: 'ยืดเหยียดแขนขาทั้งตัว',
        instructions: [
          'ยืนตรง',
          'ยกแขนทั้งสองขึ้นเหนือศีรษะ',
          'ยืดเท้าเล็กน้อย',
          'ยืดเหยียดทั้งตัว 10 วินาที',
        ],
        painPointId: 5, // Upper back - but good for all
        benefits: ['ยืดกล้ามเนื้อทั้งตัว', 'เพิ่มความตื่นตัว'],
      ),

      Treatment.createRelaxation(
        id: 25,
        nameTh: 'ผ่อนคลายทั้งตัว',
        nameEn: 'Progressive Muscle Relaxation',
        description: 'ผ่อนคลายกล้ามเนื้อทีละส่วน',
        instructions: [
          'นั่งสบายๆ',
          'เกร็งกล้ามเนื้อเท้า 5 วินาที แล้วคลาย',
          'เกร็งกล้ามเนื้อขา 5 วินาที แล้วคลาย',
          'ทำไปทั่วทั้งตัวจนถึงศีรษะ',
        ],
        painPointId: 6, // Lower back - but good for all
        duration: 120,
        benefits: ['ผ่อนคลายทั้งตัว', 'ลดความเครียด'],
      ),
    ];

    for (final treatment in treatments) {
      await box.put(treatment.id, treatment);
    }

    debugPrint('✅ Treatments seeded: ${treatments.length} items');
  }

  /// Load user settings
  Future<UserSettings> loadSettings() async {
    final box = await HiveBoxes.settingsBox;
    final settings = box.get('user_settings');

    if (settings == null) {
      final defaultSettings = UserSettings.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    }

    return settings;
  }

  /// Save user settings
  Future<void> saveSettings(UserSettings settings) async {
    final box = await HiveBoxes.settingsBox;
    await box.put('user_settings', settings);
    debugPrint('💾 Settings saved');
  }

  /// Get pain point by ID
  Future<PainPoint?> getPainPointById(int id) async {
    final box = await HiveBoxes.painPointsBox;
    return box.get(id);
  }

  /// Get all pain points
  Future<List<PainPoint>> getAllPainPoints() async {
    final box = await HiveBoxes.painPointsBox;
    return box.values.cast<PainPoint>().toList();
  }

  /// Get treatments by pain point ID
  Future<List<Treatment>> getTreatmentsByPainPointId(int painPointId) async {
    final box = await HiveBoxes.treatmentsBox;
    return box.values
        .cast<Treatment>()
        .where((treatment) =>
            treatment.painPointId == painPointId && treatment.isActive)
        .toList();
  }

  /// Get treatments by IDs
  Future<List<Treatment>> getTreatmentsByIds(List<int> ids) async {
    final box = await HiveBoxes.treatmentsBox;
    return ids
        .map((id) => box.get(id))
        .where((treatment) => treatment != null)
        .cast<Treatment>()
        .toList();
  }

  /// Save notification session
  Future<void> saveNotificationSession(NotificationSession session) async {
    final box = await HiveBoxes.notificationSessionsBox;
    await box.put(session.id, session);
    debugPrint('💾 Notification session saved: ${session.id}');
  }

  /// Get notification session
  Future<NotificationSession?> getNotificationSession(String id) async {
    final box = await HiveBoxes.notificationSessionsBox;
    return box.get(id);
  }

  /// Get recent sessions (for statistics)
  Future<List<NotificationSession>> getRecentSessions({int days = 7}) async {
    final box = await HiveBoxes.notificationSessionsBox;
    final cutoff = DateTime.now().subtract(Duration(days: days));

    return box.values
        .cast<NotificationSession>()
        .where((session) => session.scheduledTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
  }

  /// Clear old sessions (cleanup)
  Future<void> clearOldSessions({int keepDays = 30}) async {
    try {
      final box = await HiveBoxes.notificationSessionsBox;
      final cutoff = DateTime.now().subtract(Duration(days: keepDays));

      final oldSessionIds = box.values
          .cast<NotificationSession>()
          .where((session) => session.scheduledTime.isBefore(cutoff))
          .map((session) => session.id)
          .toList();

      for (final id in oldSessionIds) {
        await box.delete(id);
      }

      debugPrint('🗑️ Cleared ${oldSessionIds.length} old sessions');
    } catch (e) {
      debugPrint('❌ Error clearing old sessions: $e');
    }
  }

  /// Get statistics data
  Future<Map<String, dynamic>> getStatistics({int days = 7}) async {
    try {
      final sessions = await getRecentSessions(days: days);

      final total = sessions.length;
      final completed =
          sessions.where((s) => s.status == SessionStatusHive.completed).length;
      final skipped =
          sessions.where((s) => s.status == SessionStatusHive.skipped).length;
      final snoozed =
          sessions.where((s) => s.status == SessionStatusHive.snoozed).length;

      final completionRate = total > 0 ? completed / total : 0.0;

      return {
        'totalSessions': total,
        'completedSessions': completed,
        'skippedSessions': skipped,
        'snoozedSessions': snoozed,
        'completionRate': completionRate,
        'sessions': sessions,
      };
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {
        'totalSessions': 0,
        'completedSessions': 0,
        'skippedSessions': 0,
        'snoozedSessions': 0,
        'completionRate': 0.0,
        'sessions': <NotificationSession>[],
      };
    }
  }

  /// Factory reset (clear all data)
  Future<void> factoryReset() async {
    try {
      await HiveBoxes.clearAllData();
      await _seedInitialData();
      debugPrint('🔄 Factory reset completed');
    } catch (e) {
      debugPrint('❌ Error during factory reset: $e');
      rethrow;
    }
  }

  /// Export data (for backup)
  Future<Map<String, dynamic>> exportData() async {
    try {
      final settings = await loadSettings();
      final sessions = await getRecentSessions(days: 365); // Last year

      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'settings': {
          'selectedPainPointIds': settings.selectedPainPointIds,
          'notificationInterval': settings.notificationInterval,
          'isNotificationEnabled': settings.isNotificationEnabled,
          'isSoundEnabled': settings.isSoundEnabled,
          'isVibrationEnabled': settings.isVibrationEnabled,
          'workStartTime': settings.workStartTime,
          'workEndTime': settings.workEndTime,
          'workingDays': settings.workingDays,
          'breakTimes': settings.breakTimes,
          'snoozeInterval': settings.snoozeInterval,
        },
        'sessions': sessions
            .map((session) => {
                  'id': session.id,
                  'scheduledTime': session.scheduledTime.toIso8601String(),
                  'painPointId': session.painPointId,
                  'treatmentIds': session.treatmentIds,
                  'status': session.status.index,
                  'completedTime': session.completedTime?.toIso8601String(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('❌ Error exporting data: $e');
      rethrow;
    }
  }

  /// Import data (from backup)
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // Validate data structure
      if (data['version'] != '1.0') {
        debugPrint('❌ Unsupported backup version');
        return false;
      }

      // Import settings
      final settingsData = data['settings'] as Map<String, dynamic>;
      final currentSettings = await loadSettings();

      final importedSettings = currentSettings.copyWith(
        selectedPainPointIds:
            List<int>.from(settingsData['selectedPainPointIds'] ?? []),
        notificationInterval: settingsData['notificationInterval'] ?? 60,
        isNotificationEnabled: settingsData['isNotificationEnabled'] ?? true,
        isSoundEnabled: settingsData['isSoundEnabled'] ?? true,
        isVibrationEnabled: settingsData['isVibrationEnabled'] ?? true,
        workStartTime: settingsData['workStartTime'] ?? '09:00',
        workEndTime: settingsData['workEndTime'] ?? '17:00',
        workingDays:
            List<int>.from(settingsData['workingDays'] ?? [1, 2, 3, 4, 5]),
        breakTimes: settingsData['breakTimes'] != null
            ? List<String>.from(settingsData['breakTimes'])
            : null,
        snoozeInterval: settingsData['snoozeInterval'] ?? 5,
      );

      await saveSettings(importedSettings);

      // Import sessions (optional - might be too much data)
      // final sessionsData = data['sessions'] as List<dynamic>;
      // ... implement if needed

      debugPrint('✅ Data imported successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error importing data: $e');
      return false;
    }
  }

  /// Check database health
  Future<bool> checkDatabaseHealth() async {
    try {
      final painPointsBox = await HiveBoxes.painPointsBox;
      final treatmentsBox = await HiveBoxes.treatmentsBox;
      final settingsBox = await HiveBoxes.settingsBox;

      // Check if essential data exists
      if (painPointsBox.isEmpty || treatmentsBox.isEmpty) {
        debugPrint('⚠️ Missing essential data, re-seeding...');
        await _seedInitialData();
      }

      // Check settings
      final settings = settingsBox.get('user_settings');
      if (settings == null) {
        debugPrint('⚠️ Missing user settings, creating default...');
        await saveSettings(UserSettings.defaultSettings());
      }

      debugPrint('✅ Database health check passed');
      return true;
    } catch (e) {
      debugPrint('❌ Database health check failed: $e');
      return false;
    }
  }
}
