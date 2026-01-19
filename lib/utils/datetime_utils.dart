import 'package:intl/intl.dart';

class DateTimeUtils {
  // Formatos de fecha comunes
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    try {
      return DateFormat(format).format(date);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatDateTime(DateTime dateTime,
      {String format = 'dd/MM/yyyy HH:mm'}) {
    try {
      return DateFormat(format).format(dateTime);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy';
    } else if (dateOnly == yesterday) {
      return 'Ayer';
    } else if (dateOnly == tomorrow) {
      return 'Mañana';
    } else if (dateOnly.isAfter(today) && dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return DateFormat('EEEE', 'es_ES').format(date);
    } else {
      return formatDate(date);
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return date.isAfter(weekStart) && date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  static bool isOverdue(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.difference(today).inDays;
  }
}
