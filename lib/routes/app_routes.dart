// lib/routes/app_routes.dart
/// 🗺️ Office Syndrome Helper - Application Routes
/// กำหนด route paths สำหรับการนำทางในแอป

abstract class AppRoutes {
  // === CORE PAGES ===
  /// หน้าเริ่มต้น - Splash Screen
  static const String splash = '/';
  
  /// หน้าแบบสอบถามเลือกจุดที่ปวด
  static const String questionnaire = '/questionnaire';
  
  /// หน้าหลัก - Dashboard
  static const String home = '/home';
  
  /// หน้าทำท่าออกกำลังกาย
  static const String todo = '/todo';
  
  /// หน้าการตั้งค่า
  static const String settings = '/settings';
  
  /// หน้าสถิติ
  static const String statistics = '/statistics';
  
  // === SUB PAGES ===
  /// หน้าการตั้งค่าการแจ้งเตือน
  static const String notificationSettings = '/settings/notifications';
  
  /// หน้าการตั้งค่าสิทธิ์
  static const String permissionSettings = '/settings/permissions';
  
  /// หน้าคำแนะนำแบตเตอรี่
  static const String batteryOptimization = '/settings/battery';
  
  /// หน้าการตั้งค่าธีม
  static const String themeSettings = '/settings/theme';
  
  /// หน้าการตั้งค่าภาษา
  static const String languageSettings = '/settings/language';
  
  /// หน้าการตั้กค่าการเข้าถึง
  static const String accessibilitySettings = '/settings/accessibility';
  
  /// หน้าส่งออกข้อมูล
  static const String dataExport = '/settings/export';
  
  /// หน้าข้อมูลแอป
  static const String aboutApp = '/settings/about';
  
  // === STATISTICS SUB PAGES ===
  /// สถิติรายวัน
  static const String dailyStats = '/statistics/daily';
  
  /// สถิติรายสัปดาห์
  static const String weeklyStats = '/statistics/weekly';
  
  /// สถิติรายเดือน
  static const String monthlyStats = '/statistics/monthly';
  
  /// สถิติจุดที่ปวด
  static const String painPointStats = '/statistics/pain-points';
  
  /// สถิติการบรรลุเป้าหมาย
  static const String achievementStats = '/statistics/achievements';
  
  // === SPECIAL PAGES ===
  /// หน้าผิดพลาด - 404
  static const String notFound = '/404';
  
  /// หน้าข้อผิดพลาด
  static const String error = '/error';
  
  /// หน้าไม่มีสิทธิ์เข้าถึง
  static const String unauthorized = '/unauthorized';
  
  /// หน้าบำรุงรักษา
  static const String maintenance = '/maintenance';
  
  // === DEVELOPMENT ONLY ===
  /// หน้าทดสอบ (Development only)
  static const String debug = '/debug';
  
  /// หน้าแสดง Widgets ตัวอย่าง
  static const String widgetDemo = '/demo/widgets';
  
  /// หน้าทดสอบการแจ้งเตือน
  static const String notificationTest = '/demo/notifications';
  
  // === ROUTE GROUPS ===
  /// กลุ่ม routes หลัก
  static const List<String> mainRoutes = [
    splash,
    questionnaire,
    home,
    todo,
    settings,
    statistics,
  ];
  
  /// กลุ่ม routes การตั้งค่า
  static const List<String> settingsRoutes = [
    notificationSettings,
    permissionSettings,
    batteryOptimization,
    themeSettings,
    languageSettings,
    accessibilitySettings,
    dataExport,
    aboutApp,
  ];
  
  /// กลุ่ม routes สถิติ
  static const List<String> statisticsRoutes = [
    dailyStats,
    weeklyStats,
    monthlyStats,
    painPointStats,
    achievementStats,
  ];
  
  /// กลุ่ม routes พิเศษ
  static const List<String> specialRoutes = [
    notFound,
    error,
    unauthorized,
    maintenance,
  ];
  
  /// กลุ่ม routes สำหรับพัฒนา
  static const List<String> debugRoutes = [
    debug,
    widgetDemo,
    notificationTest,
  ];
  
  // === ROUTE UTILITIES ===
  
  /// ตรวจสอบว่าเป็น main route หรือไม่
  static bool isMainRoute(String route) {
    return mainRoutes.contains(route);
  }
  
  /// ตรวจสอบว่าเป็น settings route หรือไม่
  static bool isSettingsRoute(String route) {
    return settingsRoutes.contains(route) || route.startsWith('/settings');
  }
  
  /// ตรวจสอบว่าเป็น statistics route หรือไม่
  static bool isStatisticsRoute(String route) {
    return statisticsRoutes.contains(route) || route.startsWith('/statistics');
  }
  
  /// ตรวจสอบว่าเป็น debug route หรือไม่
  static bool isDebugRoute(String route) {
    return debugRoutes.contains(route) || route.startsWith('/debug') || route.startsWith('/demo');
  }
  
  /// รับ parent route
  static String getParentRoute(String route) {
    final segments = route.split('/');
    if (segments.length <= 2) return '/';
    
    segments.removeLast();
    return segments.join('/');
  }
  
  /// รับ route hierarchy
  static List<String> getRouteHierarchy(String route) {
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    final hierarchy = <String>[];
    
    String currentPath = '';
    for (final segment in segments) {
      currentPath += '/$segment';
      hierarchy.add(currentPath);
    }
    
    return hierarchy;
  }
  
  /// สร้าง breadcrumb navigation
  static List<RouteInfo> getBreadcrumbs(String currentRoute) {
    final breadcrumbs = <RouteInfo>[];
    final hierarchy = getRouteHierarchy(currentRoute);
    
    for (final route in hierarchy) {
      breadcrumbs.add(RouteInfo(
        path: route,
        name: _getRouteName(route),
        isActive: route == currentRoute,
      ));
    }
    
    return breadcrumbs;
  }
  
  /// รับชื่อของ route
  static String _getRouteName(String route) {
    switch (route) {
      case splash:
        return 'เริ่มต้น';
      case questionnaire:
        return 'แบบสอบถาม';
      case home:
        return 'หน้าหลัก';
      case todo:
        return 'ท่าออกกำลังกาย';
      case settings:
        return 'การตั้งค่า';
      case statistics:
        return 'สถิติ';
      case notificationSettings:
        return 'การแจ้งเตือน';
      case permissionSettings:
        return 'สิทธิ์การเข้าถึง';
      case batteryOptimization:
        return 'ประหยัดแบตเตอรี่';
      case themeSettings:
        return 'ธีม';
      case languageSettings:
        return 'ภาษา';
      case accessibilitySettings:
        return 'การเข้าถึง';
      case dataExport:
        return 'ส่งออกข้อมูล';
      case aboutApp:
        return 'เกี่ยวกับแอป';
      case dailyStats:
        return 'สถิติรายวัน';
      case weeklyStats:
        return 'สถิติรายสัปดาห์';
      case monthlyStats:
        return 'สถิติรายเดือน';
      case painPointStats:
        return 'สถิติจุดที่ปวด';
      case achievementStats:
        return 'ความสำเร็จ';
      case notFound:
        return 'ไม่พบหน้า';
      case error:
        return 'ข้อผิดพลาด';
      case unauthorized:
        return 'ไม่มีสิทธิ์';
      case maintenance:
        return 'บำรุงรักษา';
      default:
        // แปลง path เป็นชื่อที่อ่านได้
        final segments = route.split('/');
        final lastSegment = segments.isNotEmpty ? segments.last : '';
        return lastSegment.replaceAll('-', ' ').replaceAll('_', ' ');
    }
  }
  
  /// ตรวจสอบว่า route ต้องการ authentication หรือไม่
  static bool requiresAuth(String route) {
    // ปัจจุบันไม่มี authentication แต่เตรียมไว้สำหรับอนาคต
    return false;
  }
  
  /// ตรวจสอบว่า route ต้องการ permissions หรือไม่
  static bool requiresPermissions(String route) {
    final permissionRequiredRoutes = [
      home,
      todo,
      notificationSettings,
    ];
    return permissionRequiredRoutes.contains(route);
  }
  
  /// ตรวจสอบว่า route ต้องการ setup เสร็จก่อนหรือไม่
  static bool requiresSetup(String route) {
    final setupRequiredRoutes = [
      home,
      todo,
      statistics,
    ];
    return setupRequiredRoutes.contains(route);
  }
  
  /// รับ default route สำหรับผู้ใช้ใหม่
  static String getDefaultRouteForNewUser() {
    return questionnaire;
  }
  
  /// รับ default route สำหรับผู้ใช้เก่า
  static String getDefaultRouteForExistingUser() {
    return home;
  }
}

/// 📋 Route Information Model
class RouteInfo {
  final String path;
  final String name;
  final bool isActive;
  final Map<String, dynamic>? arguments;
  final List<String>? requiredPermissions;
  final bool requiresSetup;
  
  const RouteInfo({
    required this.path,
    required this.name,
    this.isActive = false,
    this.arguments,
    this.requiredPermissions,
    this.requiresSetup = false,
  });
  
  /// สร้าง RouteInfo จาก route path
  factory RouteInfo.fromRoute(String route) {
    return RouteInfo(
      path: route,
      name: AppRoutes._getRouteName(route),
      requiresSetup: AppRoutes.requiresSetup(route),
      requiredPermissions: AppRoutes.requiresPermissions(route) 
          ? ['notifications', 'alarms'] 
          : null,
    );
  }
  
  @override
  String toString() {
    return 'RouteInfo(path: $path, name: $name, isActive: $isActive)';
  }
}

/// 🔄 Route Transitions
enum RouteTransition {
  fade,
  slide,
  scale,
  rotation,
  cupertino,
  material,
  none,
}

/// 🎯 Route Metadata
class RouteMetadata {
  /// กำหนด transition สำหรับแต่ละ route
  static const Map<String, RouteTransition> transitions = {
    AppRoutes.splash: RouteTransition.fade,
    AppRoutes.questionnaire: RouteTransition.slide,
    AppRoutes.home: RouteTransition.fade,
    AppRoutes.todo: RouteTransition.slide,
    AppRoutes.settings: RouteTransition.slide,
    AppRoutes.statistics: RouteTransition.slide,
  };
  
  /// กำหนดระยะเวลา transition
  static const Map<String, Duration> transitionDurations = {
    AppRoutes.splash: Duration(milliseconds: 500),
    AppRoutes.questionnaire: Duration(milliseconds: 300),
    AppRoutes.home: Duration(milliseconds: 400),
    AppRoutes.todo: Duration(milliseconds: 300),
    AppRoutes.settings: Duration(milliseconds: 300),
    AppRoutes.statistics: Duration(milliseconds: 300),
  };
  
  /// กำหนด middleware สำหรับแต่ละ route
  static const Map<String, List<String>> middlewares = {
    AppRoutes.home: ['setup_check', 'permission_check'],
    AppRoutes.todo: ['setup_check', 'permission_check'],
    AppRoutes.statistics: ['setup_check'],
  };
  
  /// รับ transition สำหรับ route
  static RouteTransition getTransition(String route) {
    return transitions[route] ?? RouteTransition.cupertino;
  }
  
  /// รับระยะเวลา transition สำหรับ route
  static Duration getTransitionDuration(String route) {
    return transitionDurations[route] ?? const Duration(milliseconds: 300);
  }
  
  /// รับ middlewares สำหรับ route
  static List<String> getMiddlewares(String route) {
    return middlewares[route] ?? [];
  }
}