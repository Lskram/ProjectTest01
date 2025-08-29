import 'package:hive_flutter/hive_flutter.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/user_settings.dart';
import '../models/notification_session.dart';

class HiveBoxes {
  // Box names
  static const String painPointsBox = 'pain_points';
  static const String treatmentsBox = 'treatments';
  static const String settingsBox = 'user_settings';
  static const String sessionsBox = 'notification_sessions';

  // Getters สำหรับเรียกใช้ box
  static Box<PainPoint> get painPoints => Hive.box<PainPoint>(painPointsBox);
  static Box<Treatment> get treatments => Hive.box<Treatment>(treatmentsBox);
  static Box<UserSettings> get settings => Hive.box<UserSettings>(settingsBox);
  static Box<NotificationSession> get sessions =>
      Hive.box<NotificationSession>(sessionsBox);

  // Initialize Hive และเปิด boxes
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(PainPointAdapter());
    Hive.registerAdapter(TreatmentAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());
    Hive.registerAdapter(BreakPeriodAdapter());
    Hive.registerAdapter(NotificationSessionAdapter());
    Hive.registerAdapter(SessionStatusHiveAdapter());

    // Open boxes
    await Hive.openBox<PainPoint>(painPointsBox);
    await Hive.openBox<Treatment>(treatmentsBox);
    await Hive.openBox<UserSettings>(settingsBox);
    await Hive.openBox<NotificationSession>(sessionsBox);
  }

  // Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }

  // Clear all data (สำหรับ testing หรือ reset)
  static Future<void> clearAll() async {
    await painPoints.clear();
    await treatments.clear();
    await settings.clear();
    await sessions.clear();
  }
}
