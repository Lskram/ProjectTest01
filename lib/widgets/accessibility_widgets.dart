// lib/widgets/accessibility_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ♿ Office Syndrome Helper - Accessibility Widgets
/// รองรับผู้ใช้ที่มีความต้องการพิเศษ

/// 🔊 ปุ่มที่รองรับ Screen Reader
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final bool isDestructive;
  final bool isLoading;

  const AccessibleButton({
    super.key,
    required this.label,
    this.semanticLabel,
    this.tooltip,
    this.onPressed,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? label;
    final effectiveTooltip = tooltip ?? label;

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : backgroundColor,
        foregroundColor: foregroundColor,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(44, 44), // ขนาดขั้นต่ำสำหรับการแตะ
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : child ?? Text(label),
    );

    // เพิ่ม Semantics และ Tooltip
    return Semantics(
      label: effectiveLabel,
      hint: isLoading ? 'กำลังดำเนินการ' : 'แตะเพื่อ$effectiveLabel',
      button: true,
      enabled: onPressed != null && !isLoading,
      child: Tooltip(
        message: effectiveTooltip,
        child: button,
      ),
    );
  }
}

/// 📝 Text Field ที่รองรับ Accessibility
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final String? semanticLabel;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      hint: hint ?? 'ป้อน$label',
      textField: true,
      enabled: enabled,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// 🔘 Switch ที่รองรับ Accessibility
class AccessibleSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? description;
  final String? semanticLabel;

  const AccessibleSwitch({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.description,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      value: value ? 'เปิด' : 'ปิด',
      hint: 'แตะเพื่อ${value ? 'ปิด' : 'เปิด'}',
      toggled: value,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: ListTile(
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: description != null
            ? Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
        onTap: onChanged != null ? () => onChanged!(!value) : null,
      ),
    );
  }
}

/// 📊 ข้อมูลสถิติที่รองรับ Screen Reader
class AccessibleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;
  final String? description;
  final VoidCallback? onTap;

  const AccessibleStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.color,
    this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticValue = '$title: $value $unit';
    final semanticHint = description ?? 'สถิติ$title';

    return Semantics(
      label: semanticValue,
      hint: onTap != null ? 'แตะเพื่อดูรายละเอียด$semanticHint' : semanticHint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color ?? Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: color ?? Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ⏰ นาฬิกานับถอยหลังที่รองรับ Accessibility
class AccessibleCountdownWidget extends StatelessWidget {
  final Duration timeRemaining;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const AccessibleCountdownWidget({
    super.key,
    required this.timeRemaining,
    required this.label,
    this.isActive = true,
    this.onTap,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours ชั่วโมง $minutes นาที';
    } else if (minutes > 0) {
      return '$minutes นาที $seconds วินาที';
    } else {
      return '$seconds วินาที';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatDuration(timeRemaining);
    final semanticLabel = '$label: เหลือเวลาอีก $timeText';

    return Semantics(
      label: semanticLabel,
      hint: onTap != null ? 'แตะเพื่อดูรายละเอียด' : null,
      liveRegion: true, // อัปเดต Screen Reader ทุกครั้งที่เปลี่ยน
      button: onTap != null,
      child: Card(
        color: isActive
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${timeRemaining.inMinutes.toString().padLeft(2, '0')}:${(timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: isActive ? Theme.of(context).primaryColor : null,
                        fontFamily: 'monospace',
                      ),
                ),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎯 การ์ดจุดที่ปวดที่รองรับ Accessibility
class AccessiblePainPointCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
  final Color? color;
  final IconData? icon;

  const AccessiblePainPointCard({
    super.key,
    required this.name,
    required this.isSelected,
    this.onChanged,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = 'จุดที่ปวด: $name';
    final semanticValue = isSelected ? 'เลือกแล้ว' : 'ยังไม่เลือก';
    final semanticHint = 'แตะเพื่อ${isSelected ? 'ยกเลิกการเลือก' : 'เลือก'}';

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      hint: semanticHint,
      selected: isSelected,
      onTap: onChanged != null ? () => onChanged!(!isSelected) : null,
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected
            ? (color ?? Theme.of(context).primaryColor).withOpacity(0.2)
            : Theme.of(context).cardColor,
        child: InkWell(
          onTap: onChanged != null ? () => onChanged!(!isSelected) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: color ?? Theme.of(context).primaryColor,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 32,
                    color: isSelected
                        ? (color ?? Theme.of(context).primaryColor)
                        : Theme.of(context).iconTheme.color,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? (color ?? Theme.of(context).primaryColor)
                            : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.check_circle,
                    color: color ?? Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏋️ การ์ดท่าออกกำลังกายที่รองรับ Accessibility
class AccessibleExerciseCard extends StatelessWidget {
  final String name;
  final String description;
  final String duration;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isCompleted;

  const AccessibleExerciseCard({
    super.key,
    required this.name,
    required this.description,
    required this.duration,
    this.imageUrl,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = 'ท่าออกกำลังกาย: $name';
    final semanticValue = 'ระยะเวลา: $duration นาที';
    final semanticHint =
        onTap != null ? 'แตะเพื่อดูรายละเอียดและทำท่านี้' : 'ท่าออกกำลังกาย';

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      hint: semanticHint,
      button: onTap != null,
      child: Card(
        elevation: isCompleted ? 8 : 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isCompleted ? Colors.green.withOpacity(0.1) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green : null,
                            ),
                      ),
                    ),
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$duration นาที',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔊 ปุ่มเปิด/ปิดเสียงที่รองรับ Accessibility
class AccessibleSoundToggle extends StatelessWidget {
  final bool isSoundEnabled;
  final ValueChanged<bool>? onChanged;
  final String? customLabel;

  const AccessibleSoundToggle({
    super.key,
    required this.isSoundEnabled,
    this.onChanged,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? 'เสียงแจ้งเตือน';
    final semanticValue = isSoundEnabled ? 'เปิดเสียง' : 'ปิดเสียง';
    final semanticHint =
        'แตะเพื่อ${isSoundEnabled ? 'ปิด' : 'เปิด'}เสียงแจ้งเตือน';

    return Semantics(
      label: label,
      value: semanticValue,
      hint: semanticHint,
      toggled: isSoundEnabled,
      onTap: onChanged != null ? () => onChanged!(!isSoundEnabled) : null,
      child: ListTile(
        leading: Icon(
          isSoundEnabled ? Icons.volume_up : Icons.volume_off,
          color: isSoundEnabled
              ? Theme.of(context).primaryColor
              : Theme.of(context).disabledColor,
        ),
        title: Text(label),
        subtitle: Text(semanticValue),
        trailing: Switch(
          value: isSoundEnabled,
          onChanged: onChanged,
        ),
        onTap: onChanged != null ? () => onChanged!(!isSoundEnabled) : null,
      ),
    );
  }
}

/// 📱 การ์ดแสดงสถานะแอปที่รองรับ Accessibility
class AccessibleStatusCard extends StatelessWidget {
  final String status;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AccessibleStatusCard({
    super.key,
    required this.status,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = 'สถานะ: $status';
    final semanticHint =
        onTap != null ? 'แตะเพื่อดูรายละเอียดหรือแก้ไข' : 'สถานะของระบบ';

    return Semantics(
      label: semanticLabel,
      value: description,
      hint: semanticHint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: color,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎛️ Slider ที่รองรับ Accessibility
class AccessibleSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String Function(double)? labelBuilder;
  final String? unit;

  const AccessibleSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.onChanged,
    this.labelBuilder,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        labelBuilder?.call(value) ?? '${value.toStringAsFixed(0)}${unit ?? ''}';
    final semanticLabel = '$label: $displayValue';
    final semanticHint = 'ลากเพื่อปรับค่า$label';

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                displayValue,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            label: displayValue,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.toStringAsFixed(0)}${unit ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${max.toStringAsFixed(0)}${unit ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ♿ Accessibility Helper Functions
class AccessibilityHelper {
  /// ตรวจสอบว่า Screen Reader เปิดอยู่หรือไม่
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// ตรวจสอบขนาดฟอนต์ที่ผู้ใช้ตั้งค่า
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// ตรวจสอบว่าผู้ใช้ปิดการเคลื่อนไหวหรือไม่
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// ประกาศข้อความสำหรับ Screen Reader
  static void announceForScreenReader(BuildContext context, String message) {
    if (isScreenReaderEnabled(context)) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// สั่นเบาๆ สำหรับ feedback
  static void provideTactileFeedback() {
    HapticFeedback.lightImpact();
  }

  /// สั่นแรงสำหรับ error feedback
  static void provideErrorFeedback() {
    HapticFeedback.heavyImpact();
  }

  /// เล่นเสียงสำหรับ success feedback
  static void provideSuccessFeedback() {
    SystemSound.play(SystemSoundType.click);
  }
}
