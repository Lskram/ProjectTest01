// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Services
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/analytics_service.dart';

// Models (จะ auto-generate)
import 'models/user_settings.dart';
import 'models/pain_point.dart';
import 'models/treatment.dart';
import 'models/notification_session.dart';

// Themes
import 'themes/app_theme.dart';

// Routes
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

// Controllers
import 'controllers/app_controller.dart';

/// 🏁 Office Syndrome Helper - Main App Entry Point
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  try {
    // Initialize Hive database
    await Hive.initFlutter();
    
    // Register Hive adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PainPointAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TreatmentAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(NotificationSessionAdapter());
    }
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Initialize services
    await _initializeServices();
    
    debugPrint('✅ App initialization completed successfully');
  } catch (e) {
    debugPrint('❌ Error during app initialization: $e');
  }
  
  // Run the app
  runApp(OfficeSymdromeHelperApp());
}

/// Initialize all services
Future<void> _initializeServices() async {
  try {
    // 1. Database Service (ต้องเป็นตัวแรก)
    await DatabaseService.initialize();
    debugPrint('✅ DatabaseService initialized');
    
    // 2. Analytics Service (ต้องมาหลัง Database)
    await AnalyticsService.initialize();
    debugPrint('✅ AnalyticsService initialized');
    
    // 3. Permission Service
    await PermissionService.initialize();
    debugPrint('✅ PermissionService initialized');
    
    // 4. Notification Service (ต้องมาหลัง Permission)
    await NotificationService.initialize();
    debugPrint('✅ NotificationService initialized');
    
    // 5. Android Alarm Manager (Android only)
    try {
      await AndroidAlarmManager.initialize();
      debugPrint('✅ AndroidAlarmManager initialized');
    } catch (e) {
      debugPrint('⚠️ AndroidAlarmManager not available: $e');
    }
    
    // Track app launch event
    await AnalyticsService.trackAppEvent('app_launched', properties: {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Theme.of(Get.context!).platform.name,
    });
    
  } catch (e) {
    debugPrint('❌ Error initializing services: $e');
    rethrow;
  }
}

/// Main App Widget
class OfficeSymdromeHelperApp extends StatelessWidget {
  const OfficeSymdromeHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App Info
      title: 'Office Syndrome Helper',
      debugShowCheckedModeBanner: false,
      
      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // ตาม system setting
      
      // Localization
      locale: const Locale('th', 'TH'), // Default Thai
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('th', 'TH'), // Thai
        Locale('en', 'US'), // English
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Routes
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const _NotFoundPage(),
      ),
      
      // Global Bindings
      initialBinding: BindingsBuilder(() {
        // Put core controllers here
        Get.put(AppController(), permanent: true);
      }),
      
      // Route observers
      routingCallback: (routing) {
        // Track page navigation
        if (routing != null && routing.current != routing.previous) {
          AnalyticsService.trackAppEvent('page_navigation', properties: {
            'from': routing.previous ?? 'unknown',
            'to': routing.current,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      },
      
      // Default transitions
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      
      // Builder for global providers
      builder: (context, child) {
        return MediaQuery(
          // Ensure minimum text scale for accessibility
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.5,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

/// 404 Page for unknown routes
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ไม่พบหน้าที่ต้องการ'),
        leading: IconButton(
          onPressed: () => Get.offAllNamed(AppRoutes.home),
          icon: const Icon(Icons.home),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'ไม่พบหน้าที่ต้องการ',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'หน้าที่คุณกำลังหาอาจถูกย้ายหรือลบออกแล้ว',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }
}