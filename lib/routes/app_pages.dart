// lib/routes/app_pages.dart
import 'package:get/get.dart';

// Pages
import '../pages/splash_page.dart';
import '../pages/questionnaire_page.dart';
import '../pages/home_page.dart';
import '../pages/todo_page.dart';
import '../pages/settings_page.dart';
import '../pages/statistics_page.dart';

// Controllers
import '../controllers/splash_controller.dart';
import '../controllers/questionnaire_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/todo_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/statistics_controller.dart';
import '../controllers/notification_controller.dart';

// Bindings
import '../utils/bindings.dart';

// Routes
import 'app_routes.dart';

/// 🗺️ Office Syndrome Helper - App Routes Configuration
class AppPages {
  static final routes = [
    // Splash Page
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SplashController());
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    
    // Questionnaire Page
    GetPage(
      name: AppRoutes.questionnaire,
      page: () => const QuestionnairePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QuestionnaireController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Home Page
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      bindings: [
        // Core bindings for home
        BindingsBuilder(() {
          Get.lazyPut(() => HomeController());
          Get.lazyPut(() => NotificationController());
        }),
      ],
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    
    // Todo Page
    GetPage(
      name: AppRoutes.todo,
      page: () => const TodoPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TodoController());
        // Ensure notification controller is available
        if (!Get.isRegistered<NotificationController>()) {
          Get.lazyPut(() => NotificationController());
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Settings Page
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SettingsController());
        // Ensure notification controller for test notifications
        if (!Get.isRegistered<NotificationController>()) {
          Get.lazyPut(() => NotificationController());
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Statistics Page
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StatisticsController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
  
  /// 🔗 Middleware สำหรับตรวจสอบก่อนเข้าหน้า
  static final middlewares = [
    // Authentication middleware (สำหรับอนาคต)
    // AuthMiddleware(),
    
    // First time setup middleware
    FirstTimeSetupMiddleware(),
    
    // Permission middleware
    PermissionMiddleware(),
  ];
}

/// 🚧 Middleware สำหรับผู้ใช้ใหม่
class FirstTimeSetupMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;
  
  @override
  RouteSettings? redirect(String? route) {
    // ถ้าไม่ได้อยู่ในหน้า splash หรือ questionnaire
    // และยังไม่ได้ทำแบบสอบถาม ให้ redirect ไป questionnaire
    if (route != AppRoutes.splash && 
        route != AppRoutes.questionnaire) {
      
      final appController = Get.find<AppController>();
      if (!appController.isFirstTimeSetupCompleted) {
        return const RouteSettings(name: AppRoutes.questionnaire);
      }
    }
    return null;
  }
}

/// 🔐 Middleware สำหรับ Permissions
class PermissionMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;
  
  @override
  RouteSettings? redirect(String? route) {
    // สำหรับหน้าที่ต้องการ permissions
    if (route == AppRoutes.home || 
        route == AppRoutes.todo) {
      
      // ตรวจสอบ permissions (อาจจะแสดง dialog หรือ redirect)
      // ปล่อยให้หน้านั้นๆ จัดการเอง
    }
    return null;
  }
}

/// 📱 Route Guards สำหรับการป้องกันเส้นทาง
class RouteGuards {
  /// ตรวจสอบว่าสามารถเข้าหน้า home ได้หรือไม่
  static bool canAccessHome() {
    final appController = Get.find<AppController>();
    return appController.isFirstTimeSetupCompleted;
  }
  
  /// ตรวจสอบว่ามี session ที่ต้องทำหรือไม่
  static bool hasActiveTodoSession() {
    // ตรวจสอบจาก database หรือ controller
    return false; // placeholder
  }
  
  /// ตรวจสอบว่า permissions พร้อมหรือไม่
  static Future<bool> arePermissionsReady() async {
    // ตรวจสอบ permissions ที่จำเป็น
    return true; // placeholder
  }
}

/// 🎯 Route Arguments Models
class RouteArguments {
  /// Arguments สำหรับ Todo Page
  static class TodoPageArguments {
    final String? sessionId;
    final bool autoStart;
    
    const TodoPageArguments({
      this.sessionId,
      this.autoStart = false,
    });
  }
  
  /// Arguments สำหรับ Settings Page
  static class SettingsPageArguments {
    final String? section; // 'notifications', 'permissions', 'battery'
    final bool showTestDialog;
    
    const SettingsPageArguments({
      this.section,
      this.showTestDialog = false,
    });
  }
  
  /// Arguments สำหรับ Statistics Page
  static class StatisticsPageArguments {
    final String? period; // 'daily', 'weekly', 'monthly'
    final DateTime? date;
    
    const StatisticsPageArguments({
      this.period,
      this.date,
    });
  }
}

/// 🔄 Route Utilities
class RouteUtils {
  /// Navigate to home and clear stack
  static void goToHome() {
    Get.offAllNamed(AppRoutes.home);
  }
  
  /// Navigate to todo with session
  static void goToTodo({String? sessionId, bool autoStart = false}) {
    Get.toNamed(
      AppRoutes.todo,
      arguments: RouteArguments.TodoPageArguments(
        sessionId: sessionId,
        autoStart: autoStart,
      ),
    );
  }
  
  /// Navigate to settings with specific section
  static void goToSettings({String? section, bool showTestDialog = false}) {
    Get.toNamed(
      AppRoutes.settings,
      arguments: RouteArguments.SettingsPageArguments(
        section: section,
        showTestDialog: showTestDialog,
      ),
    );
  }
  
  /// Navigate to statistics with period
  static void goToStatistics({String? period, DateTime? date}) {
    Get.toNamed(
      AppRoutes.statistics,
      arguments: RouteArguments.StatisticsPageArguments(
        period: period,
        date: date,
      ),
    );
  }
  
  /// Show error and go back
  static void showErrorAndGoBack(String message) {
    Get.snackbar(
      'เกิดข้อผิดพลาด',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Get.back();
  }
  
  /// Show success message
  static void showSuccess(String message) {
    Get.snackbar(
      'สำเร็จ',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}