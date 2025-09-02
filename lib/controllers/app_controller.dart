import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // ⭐ เพิ่ม import นี้
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

enum AppState {
  loading,
  firstTime,
  ready,
  error,
}

class AppController extends GetxController {
  static AppController get instance => Get.find();

  // Reactive variables
  final _appState = AppState.loading.obs;
  final _painPoints = <PainPoint>[].obs;
  final _treatments = <Treatment>[].obs;
  final _userSettings = Rxn<UserSettings>();
  final _isInitialized = false.obs;

  // Getters
  AppState get appState => _appState.value;
  List<PainPoint> get painPoints => _painPoints;
  List<Treatment> get treatments => _treatments;
  UserSettings? get userSettings => _userSettings.value;
  bool get isInitialized => _isInitialized.value;

  // Computed properties
  List<PainPoint> get selectedPainPoints =>
      _painPoints.where((p) => p.isSelected).toList();

  bool get hasSelectedPainPoints => selectedPainPoints.isNotEmpty;

  bool get isFirstTimeUser =>
      _userSettings.value?.selectedPainPointIds.isEmpty ?? true;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  /// เริ่มต้นแอปพลิเคชัน
  Future<void> _initializeApp() async {
    try {
      _appState.value = AppState.loading;

      // Initialize services
      await _initializeServices();

      // Load data
      await _loadAppData();

      // Check if first time user
      if (isFirstTimeUser) {
        _appState.value = AppState.firstTime;
      } else {
        _appState.value = AppState.ready;

        // Start notification system
        await _initializeNotificationSystem();
      }

      _isInitialized.value = true;
      debugPrint('✅ App initialized successfully');
    } catch (e) {
      debugPrint('❌ App initialization error: $e');
      _appState.value = AppState.error;
    }
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    // Initialize database
    await DatabaseService.instance.initializeAllData();

    // Initialize notifications
    await NotificationService.instance.initialize();

    // Request permissions
    await PermissionService.instance.requestPermissionsWithExplanation();
  }

  /// Initialize notification system
  Future<void> _initializeNotificationSystem() async {
    try {
      await NotificationService.instance.scheduleNextNotification();
      debugPrint('✅ Notification system started');
    } catch (e) {
      debugPrint('❌ Notification system error: $e');
    }
  }

  /// Load app data
  Future<void> _loadAppData() async {
    // Load pain points
    final painPointsList = DatabaseService.instance.getAllPainPoints();
    _painPoints.assignAll(painPointsList);

    // Load treatments
    final treatmentsList = DatabaseService.instance.getAllTreatments();
    _treatments.assignAll(treatmentsList);

    // Load user settings
    final settings = DatabaseService.instance.getUserSettings();
    _userSettings.value = settings;
  }

  /// Complete first time setup
  Future<void> completeFirstTimeSetup(List<int> selectedPainPointIds) async {
    try {
      // Select pain points
      await selectPainPoints(selectedPainPointIds);

      // Update user settings
      final currentSettings =
          _userSettings.value ?? UserSettings(); // ⭐ แก้ไข constructor call
      final updatedSettings = currentSettings.copyWith(
        selectedPainPointIds: selectedPainPointIds,
      );

      await saveUserSettings(updatedSettings);

      // Initialize notifications
      await _initializeNotificationSystem();

      // Update app state
      _appState.value = AppState.ready;

      debugPrint('✅ First time setup completed');
    } catch (e) {
      debugPrint('❌ First time setup error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาดในการตั้งค่า: $e');
    }
  }

  /// Select pain points (max 3)
  Future<void> selectPainPoints(List<int> selectedIds) async {
    try {
      // Limit to max 3
      final limitedIds = selectedIds.take(3).toList();

      // Update database
      await DatabaseService.instance.selectPainPoints(limitedIds);

      // Update local state
      final updatedPainPoints = _painPoints.map((painPoint) {
        return painPoint.copyWith(
          isSelected: limitedIds.contains(painPoint.id),
        );
      }).toList();

      _painPoints.assignAll(updatedPainPoints);

      debugPrint('✅ Pain points selected: $limitedIds');
    } catch (e) {
      debugPrint('❌ Select pain points error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// Save user settings
  Future<void> saveUserSettings(UserSettings settings) async {
    try {
      await DatabaseService.instance.saveUserSettings(settings);
      _userSettings.value = settings;

      debugPrint('✅ User settings saved');
    } catch (e) {
      debugPrint('❌ Save settings error: $e');
      Get.snackbar('Error', 'เกิดข้อผิดพลาดในการบันทึก: $e');
    }
  }

  /// Get treatments for pain point
  List<Treatment> getTreatmentsForPainPoint(int painPointId) {
    return _treatments.where((t) => t.painPointId == painPointId).toList();
  }

  /// Get pain point by ID
  PainPoint? getPainPointById(int id) {
    try {
      return _painPoints.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get treatment by ID
  Treatment? getTreatmentById(int id) {
    try {
      return _treatments.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh app data
  Future<void> refreshData() async {
    await _loadAppData();
  }

  /// Reset app to first time state (for testing)
  Future<void> resetToFirstTime() async {
    try {
      // Cancel all notifications
      await NotificationService.instance.cancelAllNotifications();

      // Clear pain point selections
      await selectPainPoints([]);

      // Reset settings
      final resetSettings = UserSettings(); // ⭐ แก้ไข constructor call
      await saveUserSettings(resetSettings);

      // Update state
      _appState.value = AppState.firstTime;

      debugPrint('✅ App reset to first time');
    } catch (e) {
      debugPrint('❌ Reset error: $e');
    }
  }
}
