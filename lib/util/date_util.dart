class DateUtil {
  static int daysUntilDate(DateTime from, DateTime to) {
    to = DateTime(from.year, to.month, to.day);
    from = from.dateOnly;

    if (to.isBefore(from)) {
      to = DateTime(from.year + 1, to.month, to.day);
    }

    return to.difference(from).inDays;
  }
}

extension on DateTime {
  /// Returns a copy of this DateTime with time set to midnight (00:00:00).
  DateTime get dateOnly => DateTime(year, month, day);
}
