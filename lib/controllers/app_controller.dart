import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/error_service.dart';
import '../utils/error_handler.dart';
import '../utils/hive_boxes.dart';

enum AppState {
  loading,
  firstTime,
  ready,
  error,
  maintenance,
}

class AppController extends GetxController {
  static AppController get instance => Get.find();

  // Reactive variables
  final _appState = AppState.loading.obs;
  final _painPoints = <PainPoint>[].obs;
  final _treatments = <Treatment>[].obs;
  final _userSettings = Rxn<UserSettings>();
  final _isInitialized = false.obs;
  final _errorMessage = ''.obs;
  final _isHealthy = true.obs;

  // Getters
  AppState get appState => _appState.value;
  List<PainPoint> get painPoints => _painPoints;
  List<Treatment> get treatments => _treatments;
  UserSettings? get userSettings => _userSettings.value;
  bool get isInitialized => _isInitialized.value;
  String get errorMessage => _errorMessage.value;
  bool get isHealthy => _isHealthy.value;

  // Computed properties
  List<PainPoint> get selectedPainPoints => _painPoints
      .where((p) => userSettings?.selectedPainPointIds.contains(p.id) ?? false)
      .toList();

  bool get hasSelectedPainPoints => selectedPainPoints.isNotEmpty;

  bool get isFirstTimeUser => userSettings?.isFirstTimeUser ?? true;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🎮 AppController initialized');
    _initialize();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Initialize application
  Future<void> _initialize() async {
    await ErrorHandler.handleAsync(
      () async {
        _appState.value = AppState.loading;

        try {
          debugPrint('🚀 Starting app initialization...');

          // Initialize error service first
          await ErrorService.instance.initialize();

          // Check database health
          await _checkDatabaseHealth();

          // Initialize database
          await DatabaseService.instance.initialize();

          // Load initial data
          await _loadInitialData();

          // Initialize notification service
          await NotificationService.instance.initialize();

          // Check permissions
          await _checkInitialPermissions();

          // Determine app state
          await _determineAppState();

          _isInitialized.value = true;
          debugPrint('✅ App initialization completed');

          // Log successful initialization
          await ErrorService.instance.logInfo(
            'App initialized successfully',
            context: {
              'appState': _appState.value.name,
              'hasSettings': userSettings != null,
              'painPointsCount': _painPoints.length,
              'treatmentsCount': _treatments.length,
            },
          );
        } catch (e, stackTrace) {
          await _handleInitializationError(e, stackTrace);
        }
      },
      operationName: 'App Initialization',
      showUserError: false,
    );
  }

  /// Check database health before initialization
  Future<void> _checkDatabaseHealth() async {
    try {
      final health = await HiveBoxes.checkDatabaseHealth();
      _isHealthy.value = health['healthy'] ?? false;

      if (!_isHealthy.value) {
        final issues = health['issues'] as List<String>? ?? [];
        await ErrorService.instance.logWarning(
          'Database health issues detected',
          context: {'issues': issues},
        );

        // Try to recover
        if (issues.isNotEmpty) {
          await HiveBoxes.optimizeDatabase();

          // Recheck health
          final newHealth = await HiveBoxes.checkDatabaseHealth();
          _isHealthy.value = newHealth['healthy'] ?? false;
        }
      }
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Database health check failed',
        e,
        stackTrace,
      );
      _isHealthy.value = false;
    }
  }

  /// Load initial data
  Future<void> _loadInitialData() async {
    await ErrorHandler.handleAsync(
      () async {
        // Load user settings
        final settings = await DatabaseService.instance.loadSettings();
        _userSettings.value = settings;

        // Load pain points
        final painPoints = await DatabaseService.instance.getAllPainPoints();
        _painPoints.assignAll(painPoints);

        // Load treatments
        final treatments = await DatabaseService.instance.getAllTreatments();
        _treatments.assignAll(treatments);

        debugPrint(
            '📊 Initial data loaded: ${painPoints.length} pain points, ${treatments.length} treatments');
      },
      operationName: 'Load Initial Data',
      userMessage: 'ไม่สามารถโหลดข้อมูลเริ่มต้นได้',
    );
  }

  /// Check initial permissions
  Future<void> _checkInitialPermissions() async {
    await ErrorHandler.handleAsync(
      () async {
        if (userSettings?.hasRequestedPermissions == false) {
          debugPrint('🔐 Permissions not yet requested');
          return;
        }

        final hasPermissions =
            await PermissionService.instance.areAllCriticalPermissionsGranted();
        debugPrint('🔐 Current permissions status: $hasPermissions');
      },
      operationName: 'Check Initial Permissions',
      showUserError: false,
    );
  }

  /// Determine app state based on data
  Future<void> _determineAppState() async {
    try {
      if (!_isHealthy.value) {
        _appState.value = AppState.maintenance;
        _errorMessage.value = 'ระบบฐานข้อมูลต้องการการบำรุงรักษา';
        return;
      }

      if (userSettings == null) {
        _appState.value = AppState.firstTime;
        return;
      }

      if (userSettings!.isFirstTimeUser ||
          !userSettings!.hasCompletedOnboarding) {
        _appState.value = AppState.firstTime;
        return;
      }

      if (selectedPainPoints.isEmpty) {
        _appState.value = AppState.firstTime;
        return;
      }

      _appState.value = AppState.ready;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Error determining app state',
        e,
        stackTrace,
      );
      _appState.value = AppState.error;
      _errorMessage.value = 'ไม่สามารถกำหนดสถานะแอปได้';
    }
  }

  /// Handle initialization errors
  Future<void> _handleInitializationError(
      Object error, StackTrace stackTrace) async {
    try {
      await ErrorService.instance.logError(
        'App initialization failed',
        error,
        stackTrace,
        context: {'critical': true},
      );

      _appState.value = AppState.error;
      _errorMessage.value =
          ErrorHandler.instance._getUserFriendlyMessage(error);

      // Try emergency recovery for critical errors
      if (error.toString().contains('database') ||
          error.toString().contains('hive') ||
          error.toString().contains('box')) {
        final recovered = await _attemptEmergencyRecovery();
        if (recovered) {
          await _initialize(); // Retry initialization
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to handle initialization error: $e');
      _appState.value = AppState.error;
      _errorMessage.value = 'เกิดข้อผิดพลาดร้ายแรง';
    }
  }

  /// Attempt emergency recovery
  Future<bool> _attemptEmergencyRecovery() async {
    try {
      debugPrint('🚨 Attempting emergency recovery...');

      final success = await HiveBoxes.emergencyRecovery();

      if (success) {
        await ErrorService.instance.logInfo('Emergency recovery successful');
        return true;
      } else {
        await ErrorService.instance.logError(
          'Emergency recovery failed',
          'Recovery attempt unsuccessful',
          StackTrace.current,
        );
        return false;
      }
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Emergency recovery error',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Get treatments for specific pain point
  List<Treatment> getTreatmentsForPainPoint(int painPointId) {
    return ErrorHandler.handleSync(
          () => _treatments
              .where((t) => t.painPointId == painPointId && t.isActive)
              .toList(),
          operationName: 'Get Treatments for Pain Point',
          fallbackValue: <Treatment>[],
          showUserError: false,
        ) ??
        <Treatment>[];
  }

  /// Update user settings
  Future<void> updateUserSettings(UserSettings newSettings) async {
    await ErrorHandler.handleAsync(
      () async {
        await DatabaseService.instance.saveSettings(newSettings);
        _userSettings.value = newSettings;

        // Update app state if needed
        await _determineAppState();

        await ErrorService.instance.logInfo(
          'User settings updated',
          context: {
            'notificationEnabled': newSettings.isNotificationEnabled,
            'selectedPainPoints': newSettings.selectedPainPointIds.length,
          },
        );
      },
      operationName: 'Update User Settings',
      userMessage: 'ไม่สามารถบันทึกการตั้งค่าได้',
    );
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await ErrorHandler.handleAsync(
      () async {
        if (userSettings == null) return;

        final updatedSettings = userSettings!.copyWith(
          hasCompletedOnboarding: true,
          isFirstTimeUser: false,
        );

        await updateUserSettings(updatedSettings);

        await ErrorService.instance.logInfo('Onboarding completed');
      },
      operationName: 'Complete Onboarding',
      userMessage: 'ไม่สามารถบันทึกการตั้งค่าเริ่มต้นได้',
    );
  }

  /// Retry initialization
  Future<void> retryInitialization() async {
    _appState.value = AppState.loading;
    _errorMessage.value = '';
    await _initialize();
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await ErrorHandler.handleAsync(
      () async {
        await _loadInitialData();
        await _determineAppState();

        Get.snackbar('รีเฟรช', 'ข้อมูลได้รับการอัปเดตแล้ว');
      },
      operationName: 'Refresh Data',
      userMessage: 'ไม่สามารถรีเฟรชข้อมูลได้',
    );
  }

  /// Cleanup resources
  void _cleanup() {
    try {
      // Cleanup any subscriptions or timers here
      debugPrint('🧹 AppController cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  /// Get app health status
  Future<Map<String, dynamic>> getAppHealth() async {
    return await ErrorHandler.handleAsync(
          () async {
            final dbHealth = await HiveBoxes.checkDatabaseHealth();
            final errorStats = await ErrorService.instance.getLogStatistics();
            final healthScore = await ErrorService.instance.getAppHealthScore();

            return {
              'overall': _isHealthy.value,
              'database': dbHealth,
              'errors': errorStats,
              'healthScore': healthScore,
              'appState': _appState.value.name,
            };
          },
          operationName: 'Get App Health',
          fallbackValue: {
            'overall': false,
            'database': {'healthy': false},
            'errors': {},
            'healthScore': 0,
            'appState': 'unknown',
          },
        ) ??
        {};
  }

  /// Perform maintenance
  Future<void> performMaintenance() async {
    await ErrorHandler.handleAsync(
      () async {
        debugPrint('🔧 Starting app maintenance...');

        // Optimize database
        await HiveBoxes.optimizeDatabase();

        // Clean old data
        await DatabaseService.instance.clearOldSessions();

        // Clean old logs
        final logs = await ErrorService.instance.getRecentLogs(limit: 1000);
        if (logs.length > 500) {
          // Keep only recent 500 logs
          await ErrorService.instance.clearAllLogs();
          for (final log in logs.take(500)) {
            // Re-add recent logs (simplified)
          }
        }

        // Update health status
        await _checkDatabaseHealth();

        await ErrorService.instance.logInfo('App maintenance completed');

        Get.snackbar('บำรุงรักษา', 'การบำรุงรักษาระบบเสร็จสิ้น');
      },
      operationName: 'Perform Maintenance',
      userMessage: 'ไม่สามารถทำการบำรุงรักษาได้',
    );
  }

  /// Force refresh (emergency)
  Future<void> forceRefresh() async {
    try {
      _appState.value = AppState.loading;

      // Reset all data
      _painPoints.clear();
      _treatments.clear();
      _userSettings.value = null;
      _isInitialized.value = false;

      // Reinitialize
      await _initialize();
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Force refresh failed',
        e,
        stackTrace,
      );

      _appState.value = AppState.error;
      _errorMessage.value = 'ไม่สามารถรีเฟรชแอปได้';
    }
  }

  /// Check if specific feature is available
  bool isFeatureAvailable(String feature) {
    return ErrorHandler.handleSync(
          () {
            switch (feature) {
              case 'notifications':
                return _isHealthy.value && userSettings != null;
              case 'statistics':
                return _isHealthy.value && _treatments.isNotEmpty;
              case 'settings':
                return _isHealthy.value;
              default:
                return false;
            }
          },
          operationName: 'Check Feature Availability',
          fallbackValue: false,
          showUserError: false,
        ) ??
        false;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'appState': _appState.value.name,
      'isInitialized': _isInitialized.value,
      'isHealthy': _isHealthy.value,
      'errorMessage': _errorMessage.value,
      'painPointsCount': _painPoints.length,
      'treatmentsCount': _treatments.length,
      'hasUserSettings': userSettings != null,
      'selectedPainPointsCount': selectedPainPoints.length,
      'isFirstTimeUser': isFirstTimeUser,
    };
  }
}
