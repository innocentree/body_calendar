import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);

  // 날짜 포맷팅
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  // 날짜 파싱
  static DateTime? parseDate(String date) {
    try {
      return _dateFormat.parse(date);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseTime(String time) {
    try {
      return _timeFormat.parse(time);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseDateTime(String dateTime) {
    try {
      return _dateTimeFormat.parse(dateTime);
    } catch (e) {
      return null;
    }
  }

  // 날짜 비교
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  // 날짜 계산
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(const Duration(days: 6));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // 날짜 차이 계산
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return (to.difference(from).inHours / 24).round();
  }

  static int weeksBetween(DateTime from, DateTime to) {
    from = startOfWeek(from);
    to = startOfWeek(to);
    return (to.difference(from).inDays / 7).round();
  }

  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }

  // 날짜 포맷팅 (상대적)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // 요일 이름
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  // 월 이름
  static String getMonthName(int month) {
    switch (month) {
      case 1:
        return '1월';
      case 2:
        return '2월';
      case 3:
        return '3월';
      case 4:
        return '4월';
      case 5:
        return '5월';
      case 6:
        return '6월';
      case 7:
        return '7월';
      case 8:
        return '8월';
      case 9:
        return '9월';
      case 10:
        return '10월';
      case 11:
        return '11월';
      case 12:
        return '12월';
      default:
        return '';
    }
  }
} 