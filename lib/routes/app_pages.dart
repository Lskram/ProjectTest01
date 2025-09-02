import 'package:get/get.dart';
import '../pages/splash_page.dart';
import '../pages/questionnaire_page.dart';
import '../pages/home_page.dart';
import '../pages/todo_page.dart';
import '../pages/settings_page.dart';
import '../pages/statistics_page.dart';
import '../utils/bindings.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: AppBindings(),
    ),
    GetPage(
      name: AppRoutes.questionnaire,
      page: () => const QuestionnairePage(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: AppRoutes.todo,
      page: () => const TodoPage(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
    ),
    GetPage(
      name: AppRoutes.statistics,
      page: () => const StatisticsPage(),
    ),
  ];
}
