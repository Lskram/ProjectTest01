import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/hive_boxes.dart';

part 'error_service.g.dart';

@HiveType(typeId: 7)
class ErrorLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  String level; // 'error', 'warning', 'info', 'debug'

  @HiveField(3)
  String message;

  @HiveField(4)
  String? stackTrace;

  @HiveField(5)
  Map<String, dynamic>? context;

  @HiveField(6)
  String? userId;

  @HiveField(7)
  String appVersion;

  @HiveField(8)
  String platform;

  ErrorLog({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.stackTrace,
    this.context,
    this.userId,
    required this.appVersion,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'message': message,
        'stackTrace': stackTrace,
        'context': context,
        'userId': userId,
        'appVersion': appVersion,
        'platform': platform,
      };

  factory ErrorLog.fromJson(Map<String, dynamic> json) => ErrorLog(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        level: json['level'],
        message: json['message'],
        stackTrace: json['stackTrace'],
        context: json['context'],
        userId: json['userId'],
        appVersion: json['appVersion'],
        platform: json['platform'],
      );
}

class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();
  ErrorService._();

  static const String _appVersion = '1.0.0';
  static const int _maxLogEntries = 500;
  static const int _maxLogAgeDays = 30;

  /// Initialize error service
  Future<void> initialize() async {
    try {
      debugPrint('🔍 Initializing ErrorService...');

      // Register global error handlers
      FlutterError.onError = _handleFlutterError;

      // Clean old logs
      await _cleanOldLogs();

      debugPrint('✅ ErrorService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing ErrorService: $e');
    }
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log the error
    logError(
      'Flutter Framework Error',
      details.exception,
      details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Log an error
  Future<void> logError(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    try {
      final errorLog = ErrorLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: 'error',
        message: message,
        stackTrace: stackTrace?.toString(),
        context: {
          'error': error?.toString(),
          ...?context,
        },
        userId: userId,
        appVersion: _appVersion,
        platform: Platform.operatingSystem,
      );

      await _saveLog(errorLog);

      if (kDebugMode) {
        debugPrint('🔴 ERROR: $message');
        debugPrint('Details: $error');
        if (stackTrace != null) {
          debugPrint('Stack: $stackTrace');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to log error: $e');
    }
  }

  /// Log a warning
  Future<void> logWarning(
    String message, {
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    try {
      final errorLog = ErrorLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: 'warning',
        message: message,
        context: context,
        userId: userId,
        appVersion: _appVersion,
        platform: Platform.operatingSystem,
      );

      await _saveLog(errorLog);

      if (kDebugMode) {
        debugPrint('🟡 WARNING: $message');
      }
    } catch (e) {
      debugPrint('❌ Failed to log warning: $e');
    }
  }

  /// Log an info message
  Future<void> logInfo(
    String message, {
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    try {
      final errorLog = ErrorLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: 'info',
        message: message,
        context: context,
        userId: userId,
        appVersion: _appVersion,
        platform: Platform.operatingSystem,
      );

      await _saveLog(errorLog);

      if (kDebugMode) {
        debugPrint('ℹ️ INFO: $message');
      }
    } catch (e) {
      debugPrint('❌ Failed to log info: $e');
    }
  }

  /// Log debug information
  Future<void> logDebug(
    String message, {
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    if (!kDebugMode) return; // Only log debug in debug mode

    try {
      final errorLog = ErrorLog(
        id: _generateId(),
        timestamp: DateTime.now(),
        level: 'debug',
        message: message,
        context: context,
        userId: userId,
        appVersion: _appVersion,
        platform: Platform.operatingSystem,
      );

      await _saveLog(errorLog);
      debugPrint('🔍 DEBUG: $message');
    } catch (e) {
      debugPrint('❌ Failed to log debug: $e');
    }
  }

  /// Save log to local storage
  Future<void> _saveLog(ErrorLog log) async {
    try {
      final box = await HiveBoxes.errorLogsBox;
      await box.put(log.id, log);

      // Clean up if too many logs
      if (box.length > _maxLogEntries) {
        await _cleanupOldEntries();
      }
    } catch (e) {
      debugPrint('❌ Failed to save log: $e');
    }
  }

  /// Clean up old log entries
  Future<void> _cleanupOldEntries() async {
    try {
      final box = await HiveBoxes.errorLogsBox;
      final logs = box.values.cast<ErrorLog>().toList();

      // Sort by timestamp (oldest first)
      logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Remove oldest entries if over limit
      final toRemove = logs.length - _maxLogEntries;
      if (toRemove > 0) {
        for (int i = 0; i < toRemove; i++) {
          await box.delete(logs[i].id);
        }
        debugPrint('🗑️ Cleaned up $toRemove old log entries');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up logs: $e');
    }
  }

  /// Clean logs older than specified days
  Future<void> _cleanOldLogs() async {
    try {
      final box = await HiveBoxes.errorLogsBox;
      final cutoff = DateTime.now().subtract(Duration(days: _maxLogAgeDays));

      final logsToDelete = <String>[];
      for (final log in box.values.cast<ErrorLog>()) {
        if (log.timestamp.isBefore(cutoff)) {
          logsToDelete.add(log.id);
        }
      }

      for (final id in logsToDelete) {
        await box.delete(id);
      }

      if (logsToDelete.isNotEmpty) {
        debugPrint('🗑️ Cleaned up ${logsToDelete.length} old logs');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old logs: $e');
    }
  }

  /// Get all logs
  Future<List<ErrorLog>> getAllLogs() async {
    try {
      final box = await HiveBoxes.errorLogsBox;
      final logs = box.values.cast<ErrorLog>().toList();

      // Sort by timestamp (newest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs;
    } catch (e) {
      debugPrint('❌ Error getting logs: $e');
      return [];
    }
  }

  /// Get logs by level
  Future<List<ErrorLog>> getLogsByLevel(String level) async {
    try {
      final logs = await getAllLogs();
      return logs.where((log) => log.level == level).toList();
    } catch (e) {
      debugPrint('❌ Error getting logs by level: $e');
      return [];
    }
  }

  /// Get recent logs (last N logs)
  Future<List<ErrorLog>> getRecentLogs({int limit = 50}) async {
    try {
      final logs = await getAllLogs();
      return logs.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting recent logs: $e');
      return [];
    }
  }

  /// Get logs for specific date range
  Future<List<ErrorLog>> getLogsInRange(DateTime start, DateTime end) async {
    try {
      final logs = await getAllLogs();
      return logs
          .where((log) =>
              log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting logs in range: $e');
      return [];
    }
  }

  /// Export logs to JSON string
  Future<String> exportLogs({
    String? level,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<ErrorLog> logs;

      if (level != null) {
        logs = await getLogsByLevel(level);
      } else if (startDate != null && endDate != null) {
        logs = await getLogsInRange(startDate, endDate);
      } else {
        logs = await getAllLogs();
      }

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': _appVersion,
        'platform': Platform.operatingSystem,
        'totalLogs': logs.length,
        'logs': logs.map((log) => log.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ Error exporting logs: $e');
      return '{"error": "Failed to export logs"}';
    }
  }

  /// Clear all logs
  Future<void> clearAllLogs() async {
    try {
      final box = await HiveBoxes.errorLogsBox;
      await box.clear();
      debugPrint('🗑️ All logs cleared');
    } catch (e) {
      debugPrint('❌ Error clearing logs: $e');
    }
  }

  /// Get log statistics
  Future<Map<String, dynamic>> getLogStatistics() async {
    try {
      final logs = await getAllLogs();

      final stats = <String, int>{};
      for (final log in logs) {
        stats[log.level] = (stats[log.level] ?? 0) + 1;
      }

      final today = DateTime.now();
      final todayLogs = logs
          .where((log) =>
              log.timestamp.year == today.year &&
              log.timestamp.month == today.month &&
              log.timestamp.day == today.day)
          .length;

      final thisWeek = today.subtract(Duration(days: 7));
      final weeklyLogs =
          logs.where((log) => log.timestamp.isAfter(thisWeek)).length;

      return {
        'total': logs.length,
        'byLevel': stats,
        'today': todayLogs,
        'thisWeek': weeklyLogs,
        'oldestLog':
            logs.isEmpty ? null : logs.last.timestamp.toIso8601String(),
        'newestLog':
            logs.isEmpty ? null : logs.first.timestamp.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting log statistics: $e');
      return {};
    }
  }

  /// Generate unique ID for log entry
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Wrap function with error handling
  Future<T?> safeCall<T>(
    Future<T> Function() function, {
    required String operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      await logError(
        'Error in $operationName',
        error,
        stackTrace,
        context: context,
      );
      return fallbackValue;
    }
  }

  /// Wrap synchronous function with error handling
  T? safeSyncCall<T>(
    T Function() function, {
    required String operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      logError(
        'Error in $operationName',
        error,
        stackTrace,
        context: context,
      );
      return fallbackValue;
    }
  }

  /// Check if critical errors exist
  Future<bool> hasCriticalErrors() async {
    try {
      final recentLogs = await getRecentLogs(limit: 100);
      final criticalCount = recentLogs
          .where((log) =>
              log.level == 'error' &&
              log.timestamp
                  .isAfter(DateTime.now().subtract(const Duration(hours: 24))))
          .length;

      return criticalCount > 10; // More than 10 errors in 24 hours
    } catch (e) {
      return false;
    }
  }

  /// Get app health score (0-100)
  Future<int> getAppHealthScore() async {
    try {
      final stats = await getLogStatistics();
      final total = stats['total'] ?? 0;
      final errors = stats['byLevel']['error'] ?? 0;
      final warnings = stats['byLevel']['warning'] ?? 0;

      if (total == 0) return 100;

      final errorRatio = errors / total;
      final warningRatio = warnings / total;

      // Calculate score (100 - penalties)
      int score = 100;
      score -= (errorRatio * 50).round(); // Errors heavily penalized
      score -= (warningRatio * 20).round(); // Warnings lightly penalized

      return score.clamp(0, 100);
    } catch (e) {
      return 50; // Default medium health if can't calculate
    }
  }
}
