import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/statistics_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(StatisticsController(), permanent: true);
  }
}
