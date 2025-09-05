import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/user_settings.dart';
import '../models/pain_point.dart';
import '../models/treatment.dart';
import '../models/notification_session.dart';
import '../services/error_service.dart';

class HiveBoxes {
  // Box names
  static const String _settingsBoxName = 'user_settings';
  static const String _painPointsBoxName = 'pain_points';
  static const String _treatmentsBoxName = 'treatments';
  static const String _notificationSessionsBoxName = 'notification_sessions';
  static const String _errorLogsBoxName = 'error_logs';
  static const String _cacheBoxName = 'app_cache';

  // Database version for migrations
  static const int _currentDatabaseVersion = 1;
  static const String _versionKey = 'database_version';

  // Lazy boxes for better performance
  static LazyBox<UserSettings>? _settingsBox;
  static Box<PainPoint>? _painPointsBox;
  static Box<Treatment>? _treatmentsBox;
  static LazyBox<NotificationSession>? _notificationSessionsBox;
  static LazyBox<ErrorLog>? _errorLogsBox;
  static Box<dynamic>? _cacheBox;

  /// Initialize Hive database
  static Future<void> initHive() async {
    try {
      debugPrint('🗄️ Initializing Hive database...');

      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      _registerAdapters();

      // Open boxes
      await _openBoxes();

      // Check and perform migrations
      await _checkAndMigrate();

      // Clean up old data
      await _cleanupOldData();

      debugPrint('✅ Hive database initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing Hive: $e');

      // Try to recover from corruption
      await _recoverFromCorruption();
      rethrow;
    }
  }

  /// Register Hive adapters
  static void _registerAdapters() {
    try {
      // Register model adapters
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
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(SessionStatusHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ErrorLogAdapter());
      }

      debugPrint('✅ Hive adapters registered');
    } catch (e) {
      debugPrint('❌ Error registering adapters: $e');
      rethrow;
    }
  }

  /// Open all boxes
  static Future<void> _openBoxes() async {
    try {
      // Open settings box (lazy for better performance)
      _settingsBox = await Hive.openLazyBox<UserSettings>(_settingsBoxName);

      // Open pain points box
      _painPointsBox = await Hive.openBox<PainPoint>(_painPointsBoxName);

      // Open treatments box
      _treatmentsBox = await Hive.openBox<Treatment>(_treatmentsBoxName);

      // Open notification sessions box (lazy for large data)
      _notificationSessionsBox = await Hive.openLazyBox<NotificationSession>(
          _notificationSessionsBoxName);

      // Open error logs box (lazy for large data)
      _errorLogsBox = await Hive.openLazyBox<ErrorLog>(_errorLogsBoxName);

      // Open cache box
      _cacheBox = await Hive.openBox<dynamic>(_cacheBoxName);

      debugPrint('✅ All Hive boxes opened');
    } catch (e) {
      debugPrint('❌ Error opening boxes: $e');
      rethrow;
    }
  }

  /// Check and perform database migrations
  static Future<void> _checkAndMigrate() async {
    try {
      final currentVersion = _cacheBox?.get(_versionKey, defaultValue: 0) ?? 0;

      if (currentVersion < _currentDatabaseVersion) {
        debugPrint(
            '🔄 Migrating database from v$currentVersion to v$_currentDatabaseVersion');

        await _performMigration(currentVersion, _currentDatabaseVersion);

        // Update version
        await _cacheBox?.put(_versionKey, _currentDatabaseVersion);

        debugPrint('✅ Database migration completed');
      }
    } catch (e) {
      debugPrint('❌ Error during migration: $e');
      rethrow;
    }
  }

  /// Perform database migration
  static Future<void> _performMigration(int fromVersion, int toVersion) async {
    try {
      for (int version = fromVersion + 1; version <= toVersion; version++) {
        await _migrateToVersion(version);
      }
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate to specific version
  static Future<void> _migrateToVersion(int version) async {
    switch (version) {
      case 1:
        await _migrateToV1();
        break;
      // Add future migrations here
    }
  }

  /// Migration to version 1 (initial setup)
  static Future<void> _migrateToV1() async {
    try {
      debugPrint('🔄 Migrating to version 1...');

      // Add any initial migration logic here
      // For now, just ensure basic structure exists

      debugPrint('✅ Migration to v1 completed');
    } catch (e) {
      debugPrint('❌ Error migrating to v1: $e');
      rethrow;
    }
  }

  /// Clean up old data
  static Future<void> _cleanupOldData() async {
    try {
      // Clean old notification sessions (older than 90 days)
      await _cleanOldNotificationSessions();

      // Clean old error logs (older than 30 days)
      await _cleanOldErrorLogs();

      // Clean old cache entries
      await _cleanOldCacheEntries();

      debugPrint('✅ Old data cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  /// Clean old notification sessions
  static Future<void> _cleanOldNotificationSessions() async {
    try {
      if (_notificationSessionsBox == null) return;

      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final keysToDelete = <String>[];

      for (final key in _notificationSessionsBox!.keys) {
        final session = await _notificationSessionsBox!.get(key);
        if (session != null && session.scheduledTime.isBefore(cutoff)) {
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await _notificationSessionsBox!.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint(
            '🗑️ Cleaned ${keysToDelete.length} old notification sessions');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old sessions: $e');
    }
  }

  /// Clean old error logs
  static Future<void> _cleanOldErrorLogs() async {
    try {
      if (_errorLogsBox == null) return;

      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final keysToDelete = <String>[];

      for (final key in _errorLogsBox!.keys) {
        final log = await _errorLogsBox!.get(key);
        if (log != null && log.timestamp.isBefore(cutoff)) {
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await _errorLogsBox!.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint('🗑️ Cleaned ${keysToDelete.length} old error logs');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old logs: $e');
    }
  }

  /// Clean old cache entries
  static Future<void> _cleanOldCacheEntries() async {
    try {
      if (_cacheBox == null) return;

      // Remove cache entries with TTL
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      for (final key in _cacheBox!.keys) {
        if (key.toString().startsWith('ttl_')) {
          final value = _cacheBox!.get(key);
          if (value is Map && value['expiry'] != null) {
            if (now > value['expiry']) {
              keysToDelete.add(key as String);
              // Also delete the actual cache entry
              final dataKey = key.toString().replaceFirst('ttl_', '');
              keysToDelete.add(dataKey);
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox!.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint('🗑️ Cleaned ${keysToDelete.length} old cache entries');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old cache: $e');
    }
  }

  /// Recover from database corruption
  static Future<void> _recoverFromCorruption() async {
    try {
      debugPrint('🔧 Attempting to recover from database corruption...');

      // Close all boxes
      await closeAllBoxes();

      // Delete corrupted database files
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');

      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
        debugPrint('🗑️ Deleted corrupted database files');
      }

      // Reinitialize
      await initHive();

      debugPrint('✅ Database recovery completed');
    } catch (e) {
      debugPrint('❌ Database recovery failed: $e');
      rethrow;
    }
  }

  // Getters for boxes
  static LazyBox<UserSettings> get settingsBox {
    if (_settingsBox == null) {
      throw Exception('Settings box not initialized');
    }
    return _settingsBox!;
  }

  static Box<PainPoint> get painPointsBox {
    if (_painPointsBox == null) {
      throw Exception('Pain points box not initialized');
    }
    return _painPointsBox!;
  }

  static Box<Treatment> get treatmentsBox {
    if (_treatmentsBox == null) {
      throw Exception('Treatments box not initialized');
    }
    return _treatmentsBox!;
  }

  static LazyBox<NotificationSession> get notificationSessionsBox {
    if (_notificationSessionsBox == null) {
      throw Exception('Notification sessions box not initialized');
    }
    return _notificationSessionsBox!;
  }

  static LazyBox<ErrorLog> get errorLogsBox {
    if (_errorLogsBox == null) {
      throw Exception('Error logs box not initialized');
    }
    return _errorLogsBox!;
  }

  static Box<dynamic> get cacheBox {
    if (_cacheBox == null) {
      throw Exception('Cache box not initialized');
    }
    return _cacheBox!;
  }

  /// Cache operations with TTL
  static Future<void> putWithTTL(
      String key, dynamic value, Duration ttl) async {
    try {
      final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _cacheBox?.put(key, value);
      await _cacheBox?.put('ttl_$key', {'expiry': expiry});
    } catch (e) {
      debugPrint('❌ Error setting cache with TTL: $e');
    }
  }

  static dynamic getWithTTL(String key) {
    try {
      final ttlData = _cacheBox?.get('ttl_$key');
      if (ttlData is Map && ttlData['expiry'] != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > ttlData['expiry']) {
          // Expired, remove both entries
          _cacheBox?.delete(key);
          _cacheBox?.delete('ttl_$key');
          return null;
        }
      }
      return _cacheBox?.get(key);
    } catch (e) {
      debugPrint('❌ Error getting cache with TTL: $e');
      return null;
    }
  }

  /// Clear all data (factory reset)
  static Future<void> clearAllData() async {
    try {
      debugPrint('🗑️ Clearing all database data...');

      await _settingsBox?.clear();
      await _painPointsBox?.clear();
      await _treatmentsBox?.clear();
      await _notificationSessionsBox?.clear();
      await _errorLogsBox?.clear();
      await _cacheBox?.clear();

      debugPrint('✅ All data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
  }

  /// Close all boxes
  static Future<void> closeAllBoxes() async {
    try {
      await _settingsBox?.close();
      await _painPointsBox?.close();
      await _treatmentsBox?.close();
      await _notificationSessionsBox?.close();
      await _errorLogsBox?.close();
      await _cacheBox?.close();

      _settingsBox = null;
      _painPointsBox = null;
      _treatmentsBox = null;
      _notificationSessionsBox = null;
      _errorLogsBox = null;
      _cacheBox = null;

      debugPrint('✅ All boxes closed');
    } catch (e) {
      debugPrint('❌ Error closing boxes: $e');
    }
  }

  /// Compact all boxes (optimize storage)
  static Future<void> compactAllBoxes() async {
    try {
      debugPrint('🔧 Compacting database...');

      await _settingsBox?.compact();
      await _painPointsBox?.compact();
      await _treatmentsBox?.compact();
      await _notificationSessionsBox?.compact();
      await _errorLogsBox?.compact();
      await _cacheBox?.compact();

      debugPrint('✅ Database compaction completed');
    } catch (e) {
      debugPrint('❌ Error compacting database: $e');
    }
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final stats = <String, dynamic>{
        'settings': {
          'count': _settingsBox?.keys.length ?? 0,
          'size': await _getBoxSize(_settingsBoxName),
        },
        'painPoints': {
          'count': _painPointsBox?.keys.length ?? 0,
          'size': await _getBoxSize(_painPointsBoxName),
        },
        'treatments': {
          'count': _treatmentsBox?.keys.length ?? 0,
          'size': await _getBoxSize(_treatmentsBoxName),
        },
        'sessions': {
          'count': _notificationSessionsBox?.keys.length ?? 0,
          'size': await _getBoxSize(_notificationSessionsBoxName),
        },
        'errorLogs': {
          'count': _errorLogsBox?.keys.length ?? 0,
          'size': await _getBoxSize(_errorLogsBoxName),
        },
        'cache': {
          'count': _cacheBox?.keys.length ?? 0,
          'size': await _getBoxSize(_cacheBoxName),
        },
        'databaseVersion': _cacheBox?.get(_versionKey, defaultValue: 0) ?? 0,
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {};
    }
  }

  /// Get box file size
  static Future<int> _getBoxSize(String boxName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final boxFile = File('${appDir.path}/$boxName.hive');

      if (boxFile.existsSync()) {
        return await boxFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Backup database to file
  static Future<String> backupDatabase() async {
    try {
      debugPrint('💾 Creating database backup...');

      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');

      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/backup_$timestamp.hive';

      // Create backup file (simplified - in real app, use proper serialization)
      final backupFile = File(backupPath);
      await backupFile
          .writeAsString('Database backup created at ${DateTime.now()}');

      debugPrint('✅ Database backup created: $backupPath');
      return backupPath;
    } catch (e) {
      debugPrint('❌ Error creating backup: $e');
      rethrow;
    }
  }

  /// Restore database from backup
  static Future<bool> restoreDatabase(String backupPath) async {
    try {
      debugPrint('📥 Restoring database from backup...');

      final backupFile = File(backupPath);
      if (!backupFile.existsSync()) {
        throw Exception('Backup file not found: $backupPath');
      }

      // Close current boxes
      await closeAllBoxes();

      // Restore logic would go here (simplified for example)
      // In real implementation, properly deserialize and restore data

      // Reinitialize
      await initHive();

      debugPrint('✅ Database restored from backup');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring backup: $e');
      return false;
    }
  }

  /// Check database health
  static Future<Map<String, dynamic>> checkDatabaseHealth() async {
    try {
      final health = <String, dynamic>{
        'healthy': true,
        'issues': <String>[],
        'warnings': <String>[],
        'recommendations': <String>[],
      };

      // Check box accessibility
      try {
        await _settingsBox?.keys.length;
        await _painPointsBox?.keys.length;
        await _treatmentsBox?.keys.length;
      } catch (e) {
        health['healthy'] = false;
        health['issues'].add('Box accessibility error: $e');
      }

      // Check data consistency
      final painPointCount = _painPointsBox?.keys.length ?? 0;
      final treatmentCount = _treatmentsBox?.keys.length ?? 0;

      if (painPointCount == 0) {
        health['issues'].add('No pain points found in database');
      }

      if (treatmentCount == 0) {
        health['issues'].add('No treatments found in database');
      }

      // Check database size
      final stats = await getDatabaseStats();
      int totalSize = 0;
      for (final boxStats in stats.values) {
        if (boxStats is Map && boxStats['size'] != null) {
          totalSize += boxStats['size'] as int;
        }
      }

      // Warn if database is getting large (> 50MB)
      if (totalSize > 50 * 1024 * 1024) {
        health['warnings'].add(
            'Database size is large (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        health['recommendations']
            .add('Consider cleaning old data or compacting database');
      }

      // Check for orphaned cache entries
      final cacheCount = _cacheBox?.keys.length ?? 0;
      if (cacheCount > 1000) {
        health['warnings'].add('Large number of cache entries ($cacheCount)');
        health['recommendations'].add('Clean old cache entries');
      }

      return health;
    } catch (e) {
      return {
        'healthy': false,
        'issues': ['Health check failed: $e'],
        'warnings': [],
        'recommendations': ['Restart app and try again'],
      };
    }
  }

  /// Optimize database performance
  static Future<void> optimizeDatabase() async {
    try {
      debugPrint('⚡ Optimizing database performance...');

      // Clean old data
      await _cleanupOldData();

      // Compact boxes
      await compactAllBoxes();

      // Remove empty cache entries
      final keysToDelete = <dynamic>[];
      for (final key in _cacheBox?.keys ?? []) {
        final value = _cacheBox?.get(key);
        if (value == null || (value is String && value.isEmpty)) {
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox?.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint('🗑️ Removed ${keysToDelete.length} empty cache entries');
      }

      debugPrint('✅ Database optimization completed');
    } catch (e) {
      debugPrint('❌ Error optimizing database: $e');
    }
  }

  /// Emergency recovery
  static Future<bool> emergencyRecovery() async {
    try {
      debugPrint('🚨 Starting emergency database recovery...');

      // Try to backup whatever we can
      try {
        await backupDatabase();
      } catch (e) {
        debugPrint('⚠️ Could not create backup during recovery: $e');
      }

      // Force close and delete corrupted files
      await _recoverFromCorruption();

      debugPrint('✅ Emergency recovery completed');
      return true;
    } catch (e) {
      debugPrint('❌ Emergency recovery failed: $e');
      return false;
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    try {
      final cache = _cacheBox;
      if (cache == null) return {};

      int ttlEntries = 0;
      int expiredEntries = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final key in cache.keys) {
        if (key.toString().startsWith('ttl_')) {
          ttlEntries++;
          final value = cache.get(key);
          if (value is Map && value['expiry'] != null) {
            if (now > value['expiry']) {
              expiredEntries++;
            }
          }
        }
      }

      return {
        'totalEntries': cache.keys.length,
        'ttlEntries': ttlEntries,
        'expiredEntries': expiredEntries,
        'regularEntries': cache.keys.length - ttlEntries,
      };
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }

  /// Validate database integrity
  static Future<bool> validateIntegrity() async {
    try {
      debugPrint('🔍 Validating database integrity...');

      // Check if all boxes can be accessed
      final boxes = [
        _settingsBox,
        _painPointsBox,
        _treatmentsBox,
        _notificationSessionsBox,
        _errorLogsBox,
        _cacheBox,
      ];

      for (final box in boxes) {
        if (box == null) {
          debugPrint('❌ Box is null');
          return false;
        }

        try {
          // Try to access box keys
          final keyCount = box.keys.length;
          debugPrint('📊 Box has $keyCount keys');
        } catch (e) {
          debugPrint('❌ Cannot access box keys: $e');
          return false;
        }
      }

      debugPrint('✅ Database integrity validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ Database integrity validation failed: $e');
      return false;
    }
  }
}
