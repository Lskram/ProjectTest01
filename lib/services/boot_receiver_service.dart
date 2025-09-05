import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'notification_service.dart';

class BootReceiverService {
  static BootReceiverService? _instance;
  static BootReceiverService get instance =>
      _instance ??= BootReceiverService._();
  BootReceiverService._();

  /// Handle boot completed event
  @pragma('vm:entry-point')
  static Future<void> onBootCompleted() async {
    try {
      debugPrint('🔄 Device boot completed, re-initializing services...');

      // Initialize database in isolate
      await DatabaseService.instance.initializeInIsolate();

      // Load settings
      final settings = await DatabaseService.instance.loadSettings();

      if (!settings.isNotificationEnabled) {
        debugPrint('🔄 Notifications are disabled, skipping re-schedule');
        return;
      }

      // Re-initialize notification service
      await NotificationService.instance.initialize();

      // Re-schedule notifications
      final success = await NotificationService.instance.startScheduling();

      if (success) {
        debugPrint('✅ Notifications re-scheduled after boot');
      } else {
        debugPrint('❌ Failed to re-schedule notifications after boot');
      }
    } catch (e) {
      debugPrint('❌ Error handling boot completed: $e');
    }
  }

  /// Handle app update/replacement
  @pragma('vm:entry-point')
  static Future<void> onPackageReplaced() async {
    try {
      debugPrint('🔄 App updated, re-initializing services...');

      // Similar to boot completed but also check for data migration
      await onBootCompleted();

      // Check if database migration is needed
      await _checkAndMigrateData();
    } catch (e) {
      debugPrint('❌ Error handling package replacement: $e');
    }
  }

  /// Check and migrate data if needed
  static Future<void> _checkAndMigrateData() async {
    try {
      // This will be used for future database schema changes
      final settings = await DatabaseService.instance.loadSettings();

      // Example: Check if new fields are missing and add defaults
      bool needsUpdate = false;

      if (!settings.hasRequestedPermissions) {
        // This is a new field, set to false for existing users
        // They will be prompted again on next app launch
        needsUpdate = true;
      }

      if (settings.breakTimes == null) {
        // Add default break time for existing users
        needsUpdate = true;
      }

      if (needsUpdate) {
        final updatedSettings = settings.copyWith(
          hasRequestedPermissions: false, // Will prompt again
          breakTimes: settings.breakTimes ?? ['12:00-13:00'], // Default lunch
        );

        await DatabaseService.instance.saveSettings(updatedSettings);
        debugPrint('✅ Data migration completed');
      }
    } catch (e) {
      debugPrint('❌ Error migrating data: $e');
    }
  }

  /// Manual re-schedule (called from UI)
  static Future<bool> manualReschedule() async {
    try {
      debugPrint('🔄 Manual re-schedule requested');

      // Stop current scheduling
      await NotificationService.instance.stopScheduling();

      // Wait a moment
      await Future.delayed(const Duration(seconds: 1));

      // Start fresh
      final success = await NotificationService.instance.startScheduling();

      if (success) {
        debugPrint('✅ Manual re-schedule successful');
      } else {
        debugPrint('❌ Manual re-schedule failed');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error in manual re-schedule: $e');
      return false;
    }
  }
}
