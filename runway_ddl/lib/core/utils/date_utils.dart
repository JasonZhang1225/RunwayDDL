class DateUtils {
  DateUtils._();

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
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  static DateTime? parseRelativeDate(String input) {
    final normalized = input.trim().toLowerCase();

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
        return _parseAbsoluteDate(normalized);
    }
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
