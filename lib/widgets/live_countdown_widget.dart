import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../controllers/home_controller.dart';

class LiveCountdownWidget extends StatelessWidget {
  final double size;
  final bool showProgress;
  final Color? primaryColor;
  final Color? backgroundColor;

  const LiveCountdownWidget({
    super.key,
    this.size = 150,
    this.showProgress = true,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return _buildCountdownDisplay(context, controller);
      },
    );
  }

  Widget _buildCountdownDisplay(
      BuildContext context, HomeController controller) {
    final theme = Theme.of(context);
    final primary = primaryColor ?? theme.colorScheme.primary;
    final background = backgroundColor ?? theme.colorScheme.surface;

    // If no next notification time, show status
    if (controller.nextNotificationTime == null) {
      return _buildStatusDisplay(context, controller, primary, background);
    }

    // Show countdown with progress
    return _buildActiveCountdown(context, controller, primary, background);
  }

  Widget _buildStatusDisplay(
    BuildContext context,
    HomeController controller,
    Color primary,
    Color background,
  ) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (!controller.hasPermissions) {
      statusText = 'ต้องการอนุญาติ';
      statusIcon = Icons.security;
      statusColor = Colors.orange;
    } else if (!controller.isNotificationEnabled) {
      statusText = 'ปิดการแจ้งเตือน';
      statusIcon = Icons.notifications_off;
      statusColor = Colors.grey;
    } else {
      statusText = 'ไม่มีกำหนดการ';
      statusIcon = Icons.schedule;
      statusColor = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: size * 0.25,
            color: statusColor,
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCountdown(
    BuildContext context,
    HomeController controller,
    Color primary,
    Color background,
  ) {
    return Obx(() {
      final timeText = controller.timeRemaining;
      final progress = controller.progress;
      final isOverdue = timeText == 'ควรแจ้งเตือนแล้ว';

      final displayColor = isOverdue ? Colors.red : primary;

      if (!showProgress) {
        return _buildSimpleCountdown(timeText, displayColor);
      }

      return CircularPercentIndicator(
        radius: size / 2,
        lineWidth: size * 0.08,
        percent: progress.clamp(0.0, 1.0),
        center: _buildCountdownCenter(timeText, displayColor, isOverdue),
        progressColor: displayColor,
        backgroundColor: displayColor.withOpacity(0.2),
        circularStrokeCap: CircularStrokeCap.round,
        animation: true,
        animationDuration: 500,
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildSimpleCountdown(String timeText, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: _buildTimeText(timeText, color),
      ),
    );
  }

  Widget _buildCountdownCenter(String timeText, Color color, bool isOverdue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isOverdue) ...[
          Icon(
            Icons.notification_important,
            color: color,
            size: size * 0.15,
          ),
          const SizedBox(height: 4),
        ],
        _buildTimeText(timeText, color),
        const SizedBox(height: 2),
        Text(
          isOverdue ? 'เลยเวลาแล้ว' : 'เหลือเวลา',
          style: TextStyle(
            fontSize: size * 0.06,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText(String timeText, Color color) {
    // Parse time text to determine font size
    final parts = timeText.split(':');
    final fontSize = parts.length > 2
        ? size * 0.09 // Hours:Minutes:Seconds (smaller)
        : parts.length == 2
            ? size * 0.11 // Minutes:Seconds (medium)
            : size * 0.08; // Seconds only or other (smaller)

    return Text(
      timeText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Compact version for smaller spaces
class CompactCountdownWidget extends StatelessWidget {
  final HomeController controller;

  const CompactCountdownWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final timeText = controller.timeRemaining;

      if (timeText.isEmpty) {
        return const Text(
          'ไม่มีกำหนดการ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        );
      }

      final isOverdue = timeText == 'ควรแจ้งเตือนแล้ว';
      final color = isOverdue ? Colors.red : Colors.blue;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.notification_important : Icons.schedule,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    });
  }
}

/// Progress bar version
class LinearCountdownWidget extends StatelessWidget {
  final HomeController controller;
  final double height;
  final EdgeInsets margin;

  const LinearCountdownWidget({
    super.key,
    required this.controller,
    this.height = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Obx(() {
        final progress = controller.progress;
        final timeText = controller.timeRemaining;
        final isOverdue = timeText == 'ควรแจ้งเตือนแล้ว';

        if (timeText.isEmpty) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: Colors.grey.withOpacity(0.2),
            ),
          );
        }

        final color =
            isOverdue ? Colors.red : Theme.of(context).colorScheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverdue ? 'เลยเวลาแล้ว' : 'เหลือเวลา',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: height,
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Status indicator dot
class CountdownStatusDot extends StatelessWidget {
  final HomeController controller;
  final double size;

  const CountdownStatusDot({
    super.key,
    required this.controller,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Color color;

      if (!controller.hasPermissions) {
        color = Colors.orange;
      } else if (!controller.isNotificationEnabled) {
        color = Colors.grey;
      } else if (controller.timeRemaining == 'ควรแจ้งเตือนแล้ว') {
        color = Colors.red;
      } else if (controller.timeRemaining.isNotEmpty) {
        color = Colors.green;
      } else {
        color = Colors.grey;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    });
  }
}
