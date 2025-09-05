import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Utility class for date and time operations
class DateHelper {
  // Thai locale date formatters
  static final DateFormat _thaiDateFormat = DateFormat('d MMMM y', 'th_TH');
  static final DateFormat _thaiShortDateFormat = DateFormat('d MMM y', 'th_TH');
  static final DateFormat _thaiTimeFormat = DateFormat('HH:mm', 'th_TH');
  static final DateFormat _thaiDateTimeFormat = DateFormat('d MMM y HH:mm', 'th_TH');
  static final DateFormat _thaiDayFormat = DateFormat('EEEE', 'th_TH');
  
  // Standard formatters
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM y', 'th_TH');

  /// Format date in Thai format
  static String formatThaiDate(DateTime date) {
    try {
      return _thaiDateFormat.format(date);
    } catch (e) {
      debugPrint('Error formatting Thai date: $e');
      return _isoDateFormat.format(date);
    }
  }

  /// Format date in short Thai format
  static String formatThaiShortDate(DateTime date) {
    try {
      return _thaiShortDateFormat.format(date);
    } catch (e) {
      debugPrint('Error formatting Thai short date: $e');
      return _isoDateFormat.format(date);
    }
  }

  /// Format time only
  static String formatTime(DateTime date) {
    return _timeOnlyFormat.format(date);
  }

  /// Format date and time in Thai
  static String formatThaiDateTime(DateTime date) {
    try {
      return _thaiDateTimeFormat.format(date);
    } catch (e) {
      debugPrint('Error formatting Thai date time: $e');
      return '${_isoDateFormat.format(date)} ${_timeOnlyFormat.format(date)}';
    }
  }

  /// Format day name in Thai
  static String formatThaiDay(DateTime date) {
    try {
      return _thaiDayFormat.format(date);
    } catch (e) {
      debugPrint('Error formatting Thai day: $e');
      return _getEnglishDayName(date.weekday);
    }
  }

  /// Format month and year in Thai
  static String formatThaiMonthYear(DateTime date) {
    try {
      return _monthYearFormat.format(date);
    } catch (e) {
      debugPrint('Error formatting Thai month year: $e');
      return '${date.month}/${date.year}';
    }
  }

  /// Format relative time (e.g., "2 ชั่วโมงที่แล้ว")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'เมื่อวาน';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks} สัปดาห์ที่แล้ว';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months} เดือนที่แล้ว';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years} ปีที่แล้ว';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  /// Format duration in Thai
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} วัน ${duration.inHours % 24} ชั่วโมง';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ชั่วโมง ${duration.inMinutes % 60} นาที';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} นาที';
    } else {
      return '${duration.inSeconds} วินาที';
    }
  }

  /// Format time remaining
  static String formatTimeRemaining(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) {
      return 'เลยเวลาแล้ว';
    }

    if (difference.inDays > 0) {
      return 'อีก ${difference.inDays} วัน';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes > 0) {
        return 'อีก ${hours} ชั่วโมง ${minutes} นาที';
      } else {
        return 'อีก ${hours} ชั่วโมง';
      }
    } else if (difference.inMinutes > 0) {
      return 'อีก ${difference.inMinutes} นาที';
    } else {
      return 'อีก ${difference.inSeconds} วินาที';
    }
  }

  /// Parse time string (HH:mm) to TimeOfDay
  static TimeOfDay? parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time string: $e');
      return null;
    }
  }

  /// Convert TimeOfDay to string (HH:mm)
  static String timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = (date.weekday - 1) % 7;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final startWeek = startOfWeek(date);
    return endOfDay(startWeek.add(const Duration(days: 6)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return endOfDay(nextMonth.subtract(const Duration(days: 1)));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return endOfDay(DateTime(date.year, 12, 31));
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startWeek = startOfWeek(now);
    final endWeek = endOfWeek(now);
    return date.isAfter(startWeek.subtract(const Duration(milliseconds: 1))) &&
           date.isBefore(endWeek.add(const Duration(milliseconds: 1)));
  }

  /// Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is this year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Get days in month
  static int getDaysInMonth(int year, int month) {
    if (month == 2) {
      return isLeapYear(year) ? 29 : 28;
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  /// Check if year is leap year
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
  }

  /// Get week number of year
  static int getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.add(Duration(days: (8 - startOfYear.weekday) % 7));
    
    if (date.isBefore(firstMonday)) {
      return getWeekOfYear(DateTime(date.year - 1, 12, 31));
    }
    
    final weekNumber = ((date.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }

  /// Get day of year (1-366)
  static int getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  /// Format time range (e.g., "09:00 - 17:00")
  static String formatTimeRange(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  /// Parse date range string
  static List<DateTime>? parseDateRange(String range) {
    try {
      final parts = range.split(' - ');
      if (parts.length != 2) return null;
      
      final start = DateTime.parse(parts[0]);
      final end = DateTime.parse(parts[1]);
      
      return [start, end];
    } catch (e) {
      debugPrint('Error parsing date range: $e');
      return null;
    }
  }

  /// Get business days between two dates
  static int getBusinessDays(DateTime start, DateTime end) {
    if (start.isAfter(end)) return 0;
    
    int businessDays = 0;
    DateTime current = startOfDay(start);
    final endDay = startOfDay(end);
    
    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      // Monday = 1, Sunday = 7
      if (current.weekday >= 1 && current.weekday <= 5) {
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return businessDays;
  }

  /// Add business days to date
  static DateTime addBusinessDays(DateTime date, int days) {
    DateTime result = date;
    int addedDays = 0;
    
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday >= 1 && result.weekday <= 5) {
        addedDays++;
      }
    }
    
    return result;
  }

  /// Get next working day
  static DateTime getNextWorkingDay(DateTime date, List<int> workingDays) {
    DateTime next = date.add(const Duration(days: 1));
    
    while (!workingDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }
    
    return next;
  }

  /// Check if time is within range
  static bool isTimeInRange(DateTime time, String startTime, String endTime) {
    final timeOfDay = time.hour * 60 + time.minute;
    
    final start = parseTimeString(startTime);
    final end = parseTimeString(endTime);
    
    if (start == null || end == null) return false;
    
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return timeOfDay >= startMinutes && timeOfDay <= endMinutes;
  }

  /// Get age from birthdate
  static int getAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    
    return age;
  }

  /// Format age in Thai
  static String formatAge(DateTime birthdate) {
    final age = getAge(birthdate);
    return '$age ปี';
  }

  /// Get Thai day name from weekday number
  static String getThaiDayName(int weekday) {
    const dayNames = [
      'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 
      'ศุกร์', 'เสาร์', 'อาทิตย์'
    ];
    
    if (weekday < 1 || weekday > 7) return '';
    return dayNames[weekday - 1];
  }

  /// Get short Thai day name from weekday number
  static String getShortThaiDayName(int weekday) {
    const dayNames = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    
    if (weekday < 1 || weekday > 7) return '';
    return dayNames[weekday - 1];
  }

  /// Get English day name (fallback)
  static String _getEnglishDayName(int weekday) {
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    
    if (weekday < 1 || weekday > 7) return '';
    return dayNames[weekday - 1];
  }

  /// Get Thai month name
  static String getThaiMonthName(int month) {
    const monthNames = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    
    if (month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }

  /// Get short Thai month name
  static String getShortThaiMonthName(int month) {
    const monthNames = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.',
      'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.',
      'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    
    if (month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }

  /// Create date from Thai Buddhist year
  static DateTime fromBuddhistYear(int buddhistYear, int month, int day) {
    final gregorianYear = buddhistYear - 543;
    return DateTime(gregorianYear, month, day);
  }

  /// Convert to Thai Buddhist year
  static int toBuddhistYear(DateTime date) {
    return date.year + 543;
  }

  /// Format with Buddhist year
  static String formatBuddhistDate(DateTime date) {
    final buddhistYear = toBuddhistYear(date);
    return '${date.day} ${getThaiMonthName(date.month)} พ.ศ. $buddhistYear';
  }

  /// Validate time string format
  static bool isValidTimeFormat(String timeString) {
    final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]
      );
    return regex.hasMatch(timeString);
  }

  /// Validate date string format (yyyy-MM-dd)
  static bool isValidDateFormat(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get calendar weeks for month
  static List<List<DateTime>> getCalendarWeeks(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    final weeks = <List<DateTime>>[];
    DateTime current = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    
    while (current.isBefore(lastDay) || current.month == month) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
      
      if (week.last.isAfter(lastDay)) break;
    }
    
    return weeks;
  }

  /// Smart date formatting based on context
  static String smartFormat(DateTime date) {
    if (isToday(date)) {
      return 'วันนี้ ${formatTime(date)}';
    } else if (isYesterday(date)) {
      return 'เมื่อวาน ${formatTime(date)}';
    } else if (isTomorrow(date)) {
      return 'พรุ่งนี้ ${formatTime(date)}';
    } else if (isThisWeek(date)) {
      return '${formatThaiDay(date)} ${formatTime(date)}';
    } else if (isThisYear(date)) {
      return formatThaiShortDate(date);
    } else {
      return formatThaiDate(date);
    }
  }

  /// Calculate session statistics by time period
  static Map<String, int> calculateTimeSlotStats(List<DateTime> sessions) {
    final stats = <String, int>{
      'morning': 0,   // 06:00-12:00
      'afternoon': 0, // 12:00-18:00
      'evening': 0,   // 18:00-22:00
      'night': 0,     // 22:00-06:00
    };

    for (final session in sessions) {
      final hour = session.hour;
      
      if (hour >= 6 && hour < 12) {
        stats['morning'] = stats['morning']! + 1;
      } else if (hour >= 12 && hour < 18) {
        stats['afternoon'] = stats['afternoon']! + 1;
      } else if (hour >= 18 && hour < 22) {
        stats['evening'] = stats['evening']! + 1;
      } else {
        stats['night'] = stats['night']! + 1;
      }
    }

    return stats;
  }

  /// Get time slot name in Thai
  static String getTimeSlotName(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'เช้า';
    } else if (hour >= 12 && hour < 16) {
      return 'บ่าย';
    } else if (hour >= 16 && hour < 20) {
      return 'เย็น';
    } else {
      return 'กลางคืน';
    }
  }
}