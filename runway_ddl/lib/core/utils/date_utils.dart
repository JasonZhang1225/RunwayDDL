class DateUtils {
  DateUtils._();

  static const List<String> weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime tomorrow() {
    return today().add(const Duration(days: 1));
  }

  static DateTime dayAfter() {
    return today().add(const Duration(days: 2));
  }

  static DateTime nextMonday() {
    final t = today();
    final daysUntilMonday = (DateTime.monday - t.weekday + 7) % 7;
    return t.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  static DateTime nextFriday() {
    final t = today();
    final daysUntilFriday = (DateTime.friday - t.weekday + 7) % 7;
    return t.add(Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday));
  }

  static DateTime nextWeek() {
    return nextMonday();
  }

  static DateTime endOfMonth() {
    final t = today();
    return DateTime(t.year, t.month + 1, 0);
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateShort(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  static String formatDateWithWeekday(DateTime date) {
    return '${date.month}月${date.day}日 ${weekdayLabels[date.weekday - 1]}';
  }

  static DateTime? parseRelativeDate(String input) {
    final normalized = input.trim().toLowerCase().replaceAll('星期', '周');

    if (normalized.isEmpty || normalized == 'null') {
      return null;
    }

    switch (normalized) {
      case '今天':
        return today();
      case '明天':
        return tomorrow();
      case '后天':
        return dayAfter();
      case '下周一':
        return nextMonday();
      case '下周五':
        return nextFriday();
      case '下周':
        return nextWeek();
      case '周末':
        final t = today();
        final daysUntilSaturday = (DateTime.saturday - t.weekday + 7) % 7;
        return t.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
      case '月底':
        return endOfMonth();
      default:
        final weekdayDate = _parseWeekdayDate(normalized);
        if (weekdayDate != null) {
          return weekdayDate;
        }
        return _parseAbsoluteDate(normalized);
    }
  }

  static DateTime? _parseWeekdayDate(String input) {
    const weekdayMap = {
      '周一': DateTime.monday,
      '周二': DateTime.tuesday,
      '周三': DateTime.wednesday,
      '周四': DateTime.thursday,
      '周五': DateTime.friday,
      '周六': DateTime.saturday,
      '周日': DateTime.sunday,
      '周天': DateTime.sunday,
    };

    if (weekdayMap.containsKey(input)) {
      return _resolveUpcomingWeekday(weekdayMap[input]!, weekOffset: 0);
    }

    for (final entry in weekdayMap.entries) {
      if (input == '本${entry.key}') {
        return _resolveUpcomingWeekday(entry.value, weekOffset: 0);
      }
      if (input == '下${entry.key}' || input == '下周${entry.key.substring(1)}') {
        return _resolveUpcomingWeekday(entry.value, weekOffset: 1);
      }
    }

    return null;
  }

  static DateTime _resolveUpcomingWeekday(int weekday, {required int weekOffset}) {
    final current = today();
    final daysUntil = (weekday - current.weekday + 7) % 7;
    final baseDays = weekOffset == 0 ? daysUntil : daysUntil + 7;
    return current.add(Duration(days: baseDays));
  }

  static DateTime? _parseAbsoluteDate(String input) {
    final patterns = [
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'),
      RegExp(r'^(\d{1,2})/(\d{1,2})$'),
      RegExp(r'^(\d{1,2})月(\d{1,2})日?$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        try {
          if (pattern == patterns[0]) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
            final t = today();
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            return DateTime(t.year, month, day);
          }
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetween(DateTime a, DateTime b) {
    final aOnly = DateTime(a.year, a.month, a.day);
    final bOnly = DateTime(b.year, b.month, b.day);
    return bOnly.difference(aOnly).inDays;
  }
}
