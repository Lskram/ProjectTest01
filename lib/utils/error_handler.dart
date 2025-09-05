import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/error_service.dart';

/// Global error handler for the application
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  ErrorHandler._();

  /// Initialize global error handling
  static void initialize() {
    // Set up global error handlers
    FlutterError.onError = _handleFlutterError;

    // Handle errors outside of Flutter (isolates, etc.)
    PlatformDispatcher.instance.onError = _handlePlatformError;

    debugPrint('🛡️ Global error handler initialized');
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    // Log the error
    ErrorService.instance.logError(
      'Flutter Error: ${details.exception}',
      details.exception,
      details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'silent': details.silent,
      },
    );

    // Show user-friendly error in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // In production, show generic error message
      _showUserFriendlyError('เกิดข้อผิดพลาดในการแสดงผล');
    }
  }

  /// Handle platform errors (outside Flutter)
  static bool _handlePlatformError(Object error, StackTrace stack) {
    ErrorService.instance.logError(
      'Platform Error: $error',
      error,
      stack,
    );

    if (!kDebugMode) {
      _showUserFriendlyError('เกิดข้อผิดพลาดในระบบ');
    }

    return true; // Handled
  }

  /// Show user-friendly error message
  static void _showUserFriendlyError(String message) {
    try {
      if (Get.isRegistered<GetMaterialController>()) {
        Get.snackbar(
          'ข้อผิดพลาด',
          message,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error_outline, color: Colors.red),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      // If even snackbar fails, just print to debug
      debugPrint('Failed to show error snackbar: $e');
    }
  }

  /// Handle async operation with error catching
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    required String operationName,
    String? userMessage,
    T? fallbackValue,
    bool showUserError = true,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      // Log the error
      await ErrorService.instance.logError(
        'Error in $operationName',
        error,
        stackTrace,
        context: context,
      );

      // Show user message if needed
      if (showUserError) {
        final message = userMessage ?? _getUserFriendlyMessage(error);
        _showUserFriendlyError(message);
      }

      return fallbackValue;
    }
  }

  /// Handle sync operation with error catching
  static T? handleSync<T>(
    T Function() operation, {
    required String operationName,
    String? userMessage,
    T? fallbackValue,
    bool showUserError = true,
    Map<String, dynamic>? context,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      // Log the error
      ErrorService.instance.logError(
        'Error in $operationName',
        error,
        stackTrace,
        context: context,
      );

      // Show user message if needed
      if (showUserError) {
        final message = userMessage ?? _getUserFriendlyMessage(error);
        _showUserFriendlyError(message);
      }

      return fallbackValue;
    }
  }

  /// Handle widget building errors
  static Widget handleWidgetError({
    required String widgetName,
    Object? error,
    StackTrace? stackTrace,
    Widget? fallbackWidget,
  }) {
    // Log the error
    if (error != null) {
      ErrorService.instance.logError(
        'Widget Error in $widgetName',
        error,
        stackTrace,
        context: {'widget': widgetName},
      );
    }

    // Return fallback widget or default error widget
    return fallbackWidget ?? _buildErrorWidget(widgetName, error);
  }

  /// Build default error widget
  static Widget _buildErrorWidget(String widgetName, Object? error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'ข้อผิดพลาด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ไม่สามารถแสดง $widgetName ได้',
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (kDebugMode && error != null) ...[
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Get user-friendly message from error
  static String _getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'ปัญหาการเชื่อมต่อ กรุณาตรวจสอบอินเทอร์เน็ต';
    }

    // Permission errors
    if (errorString.contains('permission')) {
      return 'ไม่ได้รับอนุญาติ กรุณาตรวจสอบการตั้งค่า';
    }

    // File/Storage errors
    if (errorString.contains('file') ||
        errorString.contains('storage') ||
        errorString.contains('directory')) {
      return 'ปัญหาการจัดเก็บข้อมูล';
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('hive') ||
        errorString.contains('box')) {
      return 'ปัญหาฐานข้อมูล';
    }

    // Parsing errors
    if (errorString.contains('parse') ||
        errorString.contains('format') ||
        errorString.contains('json')) {
      return 'ข้อมูลไม่ถูกต้อง';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'หมดเวลา กรุณาลองใหม่';
    }

    // Generic message
    return 'เกิดข้อผิดพลาดไม่คาดคิด';
  }

  /// Show detailed error dialog (for debugging)
  static void showDetailedError({
    required String title,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (!kDebugMode) return;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Error:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  error.toString(),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                if (context != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Context:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    context.toString(),
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
                if (stackTrace != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    stackTrace.toString(),
                    style:
                        const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          if (context != null)
            TextButton(
              onPressed: () {
                // Copy to clipboard functionality could be added here
                Get.back();
              },
              child: const Text('Copy'),
            ),
        ],
      ),
    );
  }

  /// Handle navigation errors
  static void handleNavigationError(String routeName, Object error) {
    ErrorService.instance.logError(
      'Navigation Error to $routeName',
      error,
      StackTrace.current,
      context: {'route': routeName},
    );

    _showUserFriendlyError('ไม่สามารถเปิดหน้านี้ได้');
  }

  /// Handle API/Service errors
  static void handleServiceError({
    required String serviceName,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    String? userMessage,
    bool showToUser = true,
  }) {
    ErrorService.instance.logError(
      'Service Error: $serviceName.$operation',
      error,
      stackTrace ?? StackTrace.current,
      context: {
        'service': serviceName,
        'operation': operation,
      },
    );

    if (showToUser) {
      final message = userMessage ?? 'เกิดข้อผิดพลาดในการประมวลผล';
      _showUserFriendlyError(message);
    }
  }

  /// Handle validation errors
  static void handleValidationError({
    required String field,
    required String error,
    bool showToUser = true,
  }) {
    ErrorService.instance.logWarning(
      'Validation Error: $field',
      context: {
        'field': field,
        'error': error,
      },
    );

    if (showToUser) {
      _showUserFriendlyError(error);
    }
  }

  /// Create error boundary widget
  static Widget errorBoundary({
    required Widget child,
    String? boundaryName,
    Widget? fallback,
  }) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          return handleWidgetError(
            widgetName: boundaryName ?? 'ErrorBoundary',
            error: error,
            stackTrace: stackTrace,
            fallbackWidget: fallback,
          );
        }
      },
    );
  }

  /// Report critical error that requires app restart
  static Future<void> reportCriticalError({
    required String title,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await ErrorService.instance.logError(
      'CRITICAL: $title',
      error,
      stackTrace,
      context: {
        'critical': true,
        ...?context,
      },
    );

    if (!kDebugMode) {
      // In production, show restart dialog
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('ข้อผิดพลาดร้ายแรง'),
            ],
          ),
          content: const Text(
            'แอปเกิดข้อผิดพลาดร้ายแรง กรุณารีสตาร์ทแอป\n\nหากปัญหายังคงอยู่ กรุณาติดต่อผู้พัฒนา',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Force app restart (exit)
                // In real app, you might use restart_app package
                Get.back();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('รีสตาร์ท', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  /// Get error statistics for health monitoring
  static Future<Map<String, dynamic>> getErrorStatistics() async {
    try {
      return await ErrorService.instance.getLogStatistics();
    } catch (e) {
      return {
        'total': 0,
        'byLevel': {},
        'healthScore': 0,
      };
    }
  }

  /// Check if app is in healthy state
  static Future<bool> isAppHealthy() async {
    try {
      return !(await ErrorService.instance.hasCriticalErrors());
    } catch (e) {
      return false;
    }
  }
}

/// Extension for easy error handling in widgets
extension ErrorHandlerWidget on Widget {
  Widget withErrorBoundary({String? name, Widget? fallback}) {
    return ErrorHandler.errorBoundary(
      child: this,
      boundaryName: name,
      fallback: fallback,
    );
  }
}

/// Extension for easy error handling in Future operations
extension ErrorHandlerFuture<T> on Future<T> {
  Future<T?> withErrorHandling({
    required String operationName,
    String? userMessage,
    T? fallbackValue,
    bool showUserError = true,
    Map<String, dynamic>? context,
  }) {
    return ErrorHandler.handleAsync<T>(
      () => this,
      operationName: operationName,
      userMessage: userMessage,
      fallbackValue: fallbackValue,
      showUserError: showUserError,
      context: context,
    );
  }
}
