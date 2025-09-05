// lib/utils/bindings.dart
import 'package:get/get.dart';

// Core Controllers
import '../controllers/app_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/questionnaire_controller.dart';
import '../controllers/todo_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/statistics_controller.dart';

// Services
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/analytics_service.dart';
import '../services/random_service.dart';
import '../services/error_service.dart';
import '../services/export_service.dart';

/// 🔗 Office Syndrome Helper - Global Bindings
/// จัดการ Dependency Injection สำหรับ Controllers และ Services

/// หลัก - App Bindings (โหลดตอนเริ่มแอป)
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // === CORE SERVICES (Permanent) ===
    // Services เหล่านี้ต้องอยู่ตลอดชีวิตแอป
    Get.put(RandomService(), permanent: true);
    Get.put(ErrorService(), permanent: true);
    Get.put(ExportService(), permanent: true);

    // === CORE CONTROLLERS (Permanent) ===
    // Controllers หลักที่ต้องใช้ตลอด
    Get.put(AppController(), permanent: true);
    Get.put(NotificationController(), permanent: true);

    debugPrint('✅ AppBindings initialized');
  }
}

/// Splash Page Bindings
class SplashBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController());
    debugPrint('✅ SplashBindings initialized');
  }
}

/// Questionnaire Page Bindings
class QuestionnaireBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuestionnaireController());
    debugPrint('✅ QuestionnaireBindings initialized');
  }
}

/// Home Page Bindings
class HomeBindings extends Bindings {
  @override
  void dependencies() {
    // Home Controller (LazyPut เพื่อประสิทธิภาพ)
    Get.lazyPut(() => HomeController());

    // Notification Controller (ถ้ายังไม่มี)
    if (!Get.isRegistered<NotificationController>()) {
      Get.lazyPut(() => NotificationController());
    }

    debugPrint('✅ HomeBindings initialized');
  }
}

/// Todo Page Bindings
class TodoBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TodoController());

    // Ensure NotificationController is available
    if (!Get.isRegistered<NotificationController>()) {
      Get.lazyPut(() => NotificationController());
    }

    debugPrint('✅ TodoBindings initialized');
  }
}

/// Settings Page Bindings
class SettingsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController());

    // Ensure NotificationController for test notifications
    if (!Get.isRegistered<NotificationController>()) {
      Get.lazyPut(() => NotificationController());
    }

    debugPrint('✅ SettingsBindings initialized');
  }
}

/// Statistics Page Bindings
class StatisticsBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StatisticsController());
    debugPrint('✅ StatisticsBindings initialized');
  }
}

/// 🔧 Binding Utilities
class BindingUtils {
  /// ตรวจสอบว่า Controller ถูกลงทะเบียนแล้วหรือไม่
  static bool isControllerRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Get Controller หรือสร้างใหม่ถ้าไม่มี
  static T getOrCreateController<T>(T Function() create) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    } else {
      return Get.put(create());
    }
  }

  /// ลบ Controller ถ้ามี
  static void removeControllerIfExists<T>() {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
  }

  /// รีเซ็ต Controllers ที่ไม่ permanent
  static void resetNonPermanentControllers() {
    // ลบ Controllers ที่ไม่ permanent
    removeControllerIfExists<SplashController>();
    removeControllerIfExists<QuestionnaireController>();
    removeControllerIfExists<HomeController>();
    removeControllerIfExists<TodoController>();
    removeControllerIfExists<SettingsController>();
    removeControllerIfExists<StatisticsController>();

    debugPrint('✅ Non-permanent controllers reset');
  }

  /// ตรวจสอบสถานะ Memory
  static void logMemoryStatus() {
    final registeredTypes = <String>[];

    // Core Controllers
    if (Get.isRegistered<AppController>()) registeredTypes.add('AppController');
    if (Get.isRegistered<NotificationController>())
      registeredTypes.add('NotificationController');
    if (Get.isRegistered<HomeController>())
      registeredTypes.add('HomeController');
    if (Get.isRegistered<SplashController>())
      registeredTypes.add('SplashController');
    if (Get.isRegistered<QuestionnaireController>())
      registeredTypes.add('QuestionnaireController');
    if (Get.isRegistered<TodoController>())
      registeredTypes.add('TodoController');
    if (Get.isRegistered<SettingsController>())
      registeredTypes.add('SettingsController');
    if (Get.isRegistered<StatisticsController>())
      registeredTypes.add('StatisticsController');

    // Services
    if (Get.isRegistered<RandomService>()) registeredTypes.add('RandomService');
    if (Get.isRegistered<ErrorService>()) registeredTypes.add('ErrorService');
    if (Get.isRegistered<ExportService>()) registeredTypes.add('ExportService');

    debugPrint(
        '📊 Registered Controllers & Services: ${registeredTypes.join(', ')}');
    debugPrint('📊 Total registered: ${registeredTypes.length}');
  }
}

/// 🔄 Lazy Loading Strategies
class LazyBindings {
  /// สำหรับหน้าที่ไม่ค่อยใช้
  static void bindOptionalControllers() {
    // Controllers ที่ใช้เป็นครั้งคราว
    Get.lazyPut(() => ExportService(), fenix: true);
  }

  /// สำหรับ Heavy Controllers
  static void bindHeavyControllers() {
    // Controllers ที่ใช้ทรัพยากรเยอะ
    Get.lazyPut(() => StatisticsController(), fenix: true);
  }

  /// Cleanup เมื่อไม่ใช้
  static void cleanupOptionalControllers() {
    // ลบ Controllers ที่ไม่จำเป็น
    if (Get.isRegistered<StatisticsController>() &&
        Get.currentRoute != '/statistics') {
      Get.delete<StatisticsController>();
    }
  }
}

/// 🎯 Specialized Bindings สำหรับสถานการณ์เฉพาะ

/// Emergency Bindings - เมื่อเกิดปัญหา
class EmergencyBindings extends Bindings {
  @override
  void dependencies() {
    // รีเซ็ตและสร้าง Controllers ใหม่
    BindingUtils.resetNonPermanentControllers();

    // Core Controllers
    if (!Get.isRegistered<AppController>()) {
      Get.put(AppController(), permanent: true);
    }

    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }

    debugPrint('🚨 EmergencyBindings activated');
  }
}

/// Background Task Bindings
class BackgroundBindings extends Bindings {
  @override
  void dependencies() {
    // Services ที่จำเป็นสำหรับ Background Tasks
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }

    if (!Get.isRegistered<RandomService>()) {
      Get.put(RandomService(), permanent: true);
    }

    debugPrint('🔄 BackgroundBindings initialized');
  }
}

/// Testing Bindings สำหรับการทดสอบ
class TestBindings extends Bindings {
  @override
  void dependencies() {
    // Mock services สำหรับทดสอบ
    // Get.put<NotificationService>(MockNotificationService());
    // Get.put<DatabaseService>(MockDatabaseService());

    debugPrint('🧪 TestBindings initialized (Development only)');
  }
}

/// 📋 Binding Configurations
class BindingConfig {
  /// การตั้งค่าสำหรับ Production
  static const bool enableLazyLoading = true;
  static const bool enableMemoryOptimization = true;
  static const bool enableLogging = true;

  /// การตั้งค่าสำหรับ Development
  static const bool enableDebugBindings = false;
  static const bool enableMockServices = false;

  /// จำนวน Controllers สูงสุดที่เก็บใน Memory
  static const int maxControllersInMemory = 10;

  /// เวลาที่ Controller จะถูกลบออกจาก Memory (นาที)
  static const int controllerTimeoutMinutes = 30;
}

/// 🔍 Binding Diagnostics
class BindingDiagnostics {
  /// ตรวจสอบสุขภาพของ Bindings
  static Map<String, dynamic> getHealthCheck() {
    final health = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'total_registered': _getRegisteredCount(),
      'memory_usage': 'unknown', // จะต้องใช้ package เพิ่มเติม
      'critical_services_ok': _checkCriticalServices(),
      'controller_status': _getControllerStatus(),
    };

    return health;
  }

  static int _getRegisteredCount() {
    int count = 0;

    // Count Controllers
    if (Get.isRegistered<AppController>()) count++;
    if (Get.isRegistered<NotificationController>()) count++;
    if (Get.isRegistered<HomeController>()) count++;
    if (Get.isRegistered<SplashController>()) count++;
    if (Get.isRegistered<QuestionnaireController>()) count++;
    if (Get.isRegistered<TodoController>()) count++;
    if (Get.isRegistered<SettingsController>()) count++;
    if (Get.isRegistered<StatisticsController>()) count++;

    // Count Services
    if (Get.isRegistered<RandomService>()) count++;
    if (Get.isRegistered<ErrorService>()) count++;
    if (Get.isRegistered<ExportService>()) count++;

    return count;
  }

  static bool _checkCriticalServices() {
    return Get.isRegistered<AppController>() &&
        Get.isRegistered<NotificationController>();
  }

  static Map<String, bool> _getControllerStatus() {
    return {
      'AppController': Get.isRegistered<AppController>(),
      'NotificationController': Get.isRegistered<NotificationController>(),
      'HomeController': Get.isRegistered<HomeController>(),
      'SplashController': Get.isRegistered<SplashController>(),
      'QuestionnaireController': Get.isRegistered<QuestionnaireController>(),
      'TodoController': Get.isRegistered<TodoController>(),
      'SettingsController': Get.isRegistered<SettingsController>(),
      'StatisticsController': Get.isRegistered<StatisticsController>(),
    };
  }

  /// Export diagnostics สำหรับ debugging
  static String exportDiagnostics() {
    final health = getHealthCheck();
    final buffer = StringBuffer();

    buffer.writeln('=== Office Syndrome Helper - Binding Diagnostics ===');
    buffer.writeln('Timestamp: ${health['timestamp']}');
    buffer.writeln('Total Registered: ${health['total_registered']}');
    buffer.writeln('Critical Services OK: ${health['critical_services_ok']}');
    buffer.writeln('');
    buffer.writeln('Controller Status:');

    final status = health['controller_status'] as Map<String, bool>;
    status.forEach((name, isRegistered) {
      buffer.writeln('  $name: ${isRegistered ? '✅' : '❌'}');
    });

    buffer.writeln('');
    buffer.writeln('Current Route: ${Get.currentRoute}');
    buffer.writeln('Previous Route: ${Get.previousRoute}');

    return buffer.toString();
  }
}
