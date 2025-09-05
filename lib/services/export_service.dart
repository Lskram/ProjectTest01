import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/user_settings.dart';
import '../models/notification_session.dart';
import '../services/database_service.dart';
import '../services/error_service.dart';

class ExportService {
  static ExportService? _instance;
  static ExportService get instance => _instance ??= ExportService._();
  ExportService._();

  static const String _currentVersion = '1.0';
  static const String _appName = 'Office Syndrome Helper';

  /// Export all user data
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      debugPrint('📤 Starting data export...');

      final settings = await DatabaseService.instance.loadSettings();
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 365);
      final statistics =
          await DatabaseService.instance.getStatistics(days: 365);

      final exportData = {
        'metadata': {
          'version': _currentVersion,
          'appName': _appName,
          'exportDate': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
          'appVersion': '1.0.0',
        },
        'settings': _serializeSettings(settings),
        'sessions': _serializeSessions(sessions),
        'statistics': statistics,
        'preferences': {
          'hasCompletedOnboarding': settings.hasCompletedOnboarding,
          'hasRequestedPermissions': settings.hasRequestedPermissions,
          'isFirstTimeUser': settings.isFirstTimeUser,
        },
      };

      await ErrorService.instance.logInfo(
        'Data export completed successfully',
        context: {
          'sessionsCount': sessions.length,
          'settingsIncluded': true,
        },
      );

      debugPrint('✅ Data export completed');
      return exportData;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to export data',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Export settings only
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await DatabaseService.instance.loadSettings();

      return {
        'metadata': {
          'version': _currentVersion,
          'exportType': 'settings',
          'exportDate': DateTime.now().toIso8601String(),
        },
        'settings': _serializeSettings(settings),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to export settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Export sessions only
  Future<Map<String, dynamic>> exportSessions({int days = 30}) async {
    try {
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: days);

      return {
        'metadata': {
          'version': _currentVersion,
          'exportType': 'sessions',
          'exportDate': DateTime.now().toIso8601String(),
          'periodDays': days,
        },
        'sessions': _serializeSessions(sessions),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to export sessions',
        e,
        stackTrace,
        context: {'days': days},
      );
      rethrow;
    }
  }

  /// Import all data
  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      debugPrint('📥 Starting data import...');

      // Validate data structure
      if (!_validateImportData(data)) {
        throw Exception('Invalid import data structure');
      }

      // Check version compatibility
      final importVersion = data['metadata']?['version'];
      if (!_isVersionCompatible(importVersion)) {
        throw Exception('Incompatible data version: $importVersion');
      }

      // Backup current data
      final backupData = await exportAllData();

      try {
        // Import settings
        if (data['settings'] != null) {
          await _importSettings(data['settings']);
        }

        // Import sessions
        if (data['sessions'] != null) {
          await _importSessions(data['sessions']);
        }

        await ErrorService.instance.logInfo(
          'Data import completed successfully',
          context: {
            'importVersion': importVersion,
            'sessionsImported': (data['sessions'] as List?)?.length ?? 0,
          },
        );

        debugPrint('✅ Data import completed');
        return true;
      } catch (e) {
        // Restore backup on failure
        debugPrint('❌ Import failed, restoring backup...');
        await _restoreFromBackup(backupData);
        rethrow;
      }
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to import data',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Import settings only
  Future<bool> importSettings(Map<String, dynamic> data) async {
    try {
      if (data['settings'] == null) {
        throw Exception('No settings data found');
      }

      await _importSettings(data['settings']);
      return true;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to import settings',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Create backup before risky operations
  Future<String> createBackup() async {
    try {
      final backupData = await exportAllData();
      final backupJson = jsonEncode(backupData);

      // In a real app, you might save this to a file
      await ErrorService.instance.logInfo(
        'Backup created successfully',
        context: {
          'backupSize': backupJson.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return backupJson;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to create backup',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Generate export summary
  Future<Map<String, dynamic>> getExportSummary() async {
    try {
      final settings = await DatabaseService.instance.loadSettings();
      final sessions =
          await DatabaseService.instance.getRecentSessions(days: 365);
      final statistics =
          await DatabaseService.instance.getStatistics(days: 365);

      return {
        'totalSessions': sessions.length,
        'completedSessions': statistics['completedSessions'] ?? 0,
        'selectedPainPoints': settings.selectedPainPointIds.length,
        'notificationEnabled': settings.isNotificationEnabled,
        'workingDays': settings.workingDays.length,
        'oldestSession': sessions.isEmpty
            ? null
            : sessions.last.scheduledTime.toIso8601String(),
        'newestSession': sessions.isEmpty
            ? null
            : sessions.first.scheduledTime.toIso8601String(),
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to get export summary',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Serialize settings for export
  Map<String, dynamic> _serializeSettings(UserSettings settings) {
    return {
      'selectedPainPointIds': settings.selectedPainPointIds,
      'notificationInterval': settings.notificationInterval,
      'isNotificationEnabled': settings.isNotificationEnabled,
      'isSoundEnabled': settings.isSoundEnabled,
      'isVibrationEnabled': settings.isVibrationEnabled,
      'workStartTime': settings.workStartTime,
      'workEndTime': settings.workEndTime,
      'workingDays': settings.workingDays,
      'breakTimes': settings.breakTimes,
      'snoozeInterval': settings.snoozeInterval,
      'hasCompletedOnboarding': settings.hasCompletedOnboarding,
      'hasRequestedPermissions': settings.hasRequestedPermissions,
      'isFirstTimeUser': settings.isFirstTimeUser,
    };
  }

  /// Serialize sessions for export
  List<Map<String, dynamic>> _serializeSessions(
      List<NotificationSession> sessions) {
    return sessions
        .map((session) => {
              'id': session.id,
              'scheduledTime': session.scheduledTime.toIso8601String(),
              'actualStartTime': session.actualStartTime?.toIso8601String(),
              'completedTime': session.completedTime?.toIso8601String(),
              'painPointId': session.painPointId,
              'treatmentIds': session.treatmentIds,
              'status': session.status.name,
              'snoozeCount': session.snoozeCount,
              'snoozeTimes':
                  session.snoozeTimes?.map((t) => t.toIso8601String()).toList(),
              'treatmentCompleted': session.treatmentCompleted,
              'notes': session.notes,
            })
        .toList();
  }

  /// Import settings from serialized data
  Future<void> _importSettings(Map<String, dynamic> settingsData) async {
    try {
      final currentSettings = await DatabaseService.instance.loadSettings();

      final importedSettings = currentSettings.copyWith(
        selectedPainPointIds:
            List<int>.from(settingsData['selectedPainPointIds'] ?? []),
        notificationInterval: settingsData['notificationInterval'] ?? 60,
        isNotificationEnabled: settingsData['isNotificationEnabled'] ?? true,
        isSoundEnabled: settingsData['isSoundEnabled'] ?? true,
        isVibrationEnabled: settingsData['isVibrationEnabled'] ?? true,
        workStartTime: settingsData['workStartTime'] ?? '09:00',
        workEndTime: settingsData['workEndTime'] ?? '17:00',
        workingDays:
            List<int>.from(settingsData['workingDays'] ?? [1, 2, 3, 4, 5]),
        breakTimes: settingsData['breakTimes'] != null
            ? List<String>.from(settingsData['breakTimes'])
            : null,
        snoozeInterval: settingsData['snoozeInterval'] ?? 5,
        hasCompletedOnboarding: settingsData['hasCompletedOnboarding'] ?? false,
        hasRequestedPermissions:
            settingsData['hasRequestedPermissions'] ?? false,
        isFirstTimeUser: settingsData['isFirstTimeUser'] ?? true,
      );

      await DatabaseService.instance.saveSettings(importedSettings);
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to import settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Import sessions from serialized data
  Future<void> _importSessions(List<dynamic> sessionsData) async {
    try {
      for (final sessionData in sessionsData) {
        try {
          final session = NotificationSession(
            id: sessionData['id'],
            scheduledTime: DateTime.parse(sessionData['scheduledTime']),
            painPointId: sessionData['painPointId'],
            treatmentIds: List<int>.from(sessionData['treatmentIds']),
            status: _parseSessionStatus(sessionData['status']),
            snoozeCount: sessionData['snoozeCount'] ?? 0,
            actualStartTime: sessionData['actualStartTime'] != null
                ? DateTime.parse(sessionData['actualStartTime'])
                : null,
            completedTime: sessionData['completedTime'] != null
                ? DateTime.parse(sessionData['completedTime'])
                : null,
            snoozeTimes: sessionData['snoozeTimes'] != null
                ? (sessionData['snoozeTimes'] as List)
                    .map((t) => DateTime.parse(t))
                    .toList()
                : null,
            treatmentCompleted: sessionData['treatmentCompleted'] != null
                ? List<bool>.from(sessionData['treatmentCompleted'])
                : null,
            notes: sessionData['notes'],
          );

          await DatabaseService.instance.saveNotificationSession(session);
        } catch (e) {
          // Log individual session import failure but continue
          await ErrorService.instance.logWarning(
            'Failed to import individual session',
            context: {'sessionId': sessionData['id']},
          );
        }
      }
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to import sessions',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Parse session status from string
  SessionStatusHive _parseSessionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return SessionStatusHive.completed;
      case 'skipped':
        return SessionStatusHive.skipped;
      case 'snoozed':
        return SessionStatusHive.snoozed;
      case 'pending':
      default:
        return SessionStatusHive.pending;
    }
  }

  /// Validate import data structure
  bool _validateImportData(Map<String, dynamic> data) {
    try {
      // Check for required metadata
      if (data['metadata'] == null) return false;

      final metadata = data['metadata'];
      if (metadata['version'] == null || metadata['exportDate'] == null) {
        return false;
      }

      // Check for at least one data section
      if (data['settings'] == null && data['sessions'] == null) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check version compatibility
  bool _isVersionCompatible(String? version) {
    if (version == null) return false;

    // For now, only support current version
    // In future, add version migration logic
    return version == _currentVersion;
  }

  /// Restore from backup data
  Future<void> _restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      await importAllData(backupData);
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to restore from backup',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Generate encrypted export (placeholder for future encryption)
  Future<String> generateEncryptedExport({String? password}) async {
    try {
      final exportData = await exportAllData();
      final jsonData = jsonEncode(exportData);

      // For now, just return base64 encoded
      // In future, implement actual encryption
      final bytes = utf8.encode(jsonData);
      final encoded = base64Encode(bytes);

      await ErrorService.instance.logInfo(
        'Encrypted export generated',
        context: {
          'dataSize': jsonData.length,
          'encodedSize': encoded.length,
          'hasPassword': password != null,
        },
      );

      return encoded;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to generate encrypted export',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Import from encrypted export
  Future<bool> importFromEncryptedExport(String encryptedData,
      {String? password}) async {
    try {
      // For now, just decode base64
      // In future, implement actual decryption
      final bytes = base64Decode(encryptedData);
      final jsonData = utf8.decode(bytes);
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      return await importAllData(data);
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to import from encrypted export',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Clean up old export files (placeholder for file management)
  Future<void> cleanupOldExports() async {
    try {
      // This would clean up old export files from device storage
      // Implementation depends on where exports are saved

      await ErrorService.instance.logInfo('Old exports cleaned up');
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to cleanup old exports',
        e,
        stackTrace,
      );
    }
  }

  /// Validate imported data integrity
  Future<bool> validateImportIntegrity(Map<String, dynamic> data) async {
    try {
      // Basic structure validation
      if (!_validateImportData(data)) return false;

      // Settings validation
      if (data['settings'] != null) {
        final settings = data['settings'];

        // Check pain point IDs are valid
        final painPointIds = settings['selectedPainPointIds'] as List?;
        if (painPointIds != null) {
          for (final id in painPointIds) {
            if (id < 1 || id > 10) return false;
          }
        }

        // Check notification interval is reasonable
        final interval = settings['notificationInterval'];
        if (interval != null && (interval < 5 || interval > 1440)) {
          return false;
        }

        // Check working days are valid
        final workingDays = settings['workingDays'] as List?;
        if (workingDays != null) {
          for (final day in workingDays) {
            if (day < 1 || day > 7) return false;
          }
        }
      }

      // Sessions validation
      if (data['sessions'] != null) {
        final sessions = data['sessions'] as List;

        for (final session in sessions) {
          // Check required fields
          if (session['id'] == null ||
              session['scheduledTime'] == null ||
              session['painPointId'] == null ||
              session['treatmentIds'] == null) {
            return false;
          }

          // Validate dates
          try {
            DateTime.parse(session['scheduledTime']);
            if (session['completedTime'] != null) {
              DateTime.parse(session['completedTime']);
            }
          } catch (e) {
            return false;
          }
        }
      }

      return true;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to validate import integrity',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Get export file size estimate
  Future<int> getExportSizeEstimate() async {
    try {
      final summary = await getExportSummary();

      // Rough estimation based on data structure
      final settingsSize = 1024; // ~1KB for settings
      final sessionSize = 512; // ~512B per session
      final metadataSize = 512; // ~512B for metadata

      final totalSessions = summary['totalSessions'] ?? 0;
      final estimatedSize =
          settingsSize + (sessionSize * totalSessions) + metadataSize;

      return estimatedSize;
    } catch (e) {
      return 0;
    }
  }

  /// Check if export is safe (no critical data loss)
  Future<Map<String, dynamic>> checkExportSafety() async {
    try {
      final summary = await getExportSummary();
      final issues = <String>[];

      // Check for potential issues
      if (summary['totalSessions'] == 0) {
        issues.add('ไม่มีข้อมูลการใช้งาน');
      }

      if (summary['selectedPainPoints'] == 0) {
        issues.add('ไม่ได้เลือกจุดที่ปวด');
      }

      if (summary['workingDays'] == 0) {
        issues.add('ไม่ได้ตั้งวันทำงาน');
      }

      return {
        'isSafe': issues.isEmpty,
        'issues': issues,
        'summary': summary,
      };
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to check export safety',
        e,
        stackTrace,
      );
      return {
        'isSafe': false,
        'issues': ['ไม่สามารถตรวจสอบความปลอดภัยได้'],
        'summary': {},
      };
    }
  }

  /// Auto-backup functionality
  Future<void> performAutoBackup() async {
    try {
      final lastBackup = await _getLastBackupTime();
      final now = DateTime.now();

      // Auto backup every 7 days
      if (lastBackup == null || now.difference(lastBackup).inDays >= 7) {
        final backup = await createBackup();
        await _saveAutoBackup(backup);
        await _setLastBackupTime(now);

        await ErrorService.instance.logInfo(
          'Auto backup completed',
          context: {'backupSize': backup.length},
        );
      }
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Auto backup failed',
        e,
        stackTrace,
      );
    }
  }

  /// Get last backup time (placeholder for shared preferences)
  Future<DateTime?> _getLastBackupTime() async {
    // In real implementation, get from SharedPreferences
    return null;
  }

  /// Set last backup time (placeholder for shared preferences)
  Future<void> _setLastBackupTime(DateTime time) async {
    // In real implementation, save to SharedPreferences
  }

  /// Save auto backup (placeholder for file storage)
  Future<void> _saveAutoBackup(String backup) async {
    // In real implementation, save to device storage
    // Could also implement backup rotation (keep last N backups)
  }

  /// Restore from auto backup
  Future<bool> restoreFromAutoBackup() async {
    try {
      // In real implementation, load from device storage
      // For now, just return false (no backup available)
      return false;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to restore from auto backup',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Generate migration report for version upgrades
  Future<Map<String, dynamic>> generateMigrationReport(
      Map<String, dynamic> oldData) async {
    try {
      final report = <String, dynamic>{
        'sourceVersion': oldData['metadata']?['version'] ?? 'unknown',
        'targetVersion': _currentVersion,
        'migrationNeeded': false,
        'changes': <String>[],
        'warnings': <String>[],
        'dataLoss': <String>[],
      };

      // Add version-specific migration logic here
      // For now, just basic compatibility check
      if (oldData['metadata']?['version'] != _currentVersion) {
        report['migrationNeeded'] = true;
        report['changes'].add('เวอร์ชันข้อมูลจะถูกอัปเกรด');
      }

      return report;
    } catch (e, stackTrace) {
      await ErrorService.instance.logError(
        'Failed to generate migration report',
        e,
        stackTrace,
      );
      return {
        'sourceVersion': 'unknown',
        'targetVersion': _currentVersion,
        'migrationNeeded': false,
        'changes': [],
        'warnings': ['ไม่สามารถวิเคราะห์การอัปเกรดได้'],
        'dataLoss': [],
      };
    }
  }
}
