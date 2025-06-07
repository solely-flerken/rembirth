class PartialDate {
  final int? year; // nullable
  final int month;
  final int day;

  PartialDate({this.year, required this.month, required this.day});

  String format() {
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    if (year != null) {
      return '$year-$monthStr-$dayStr';
    } else {
      return '$monthStr-$dayStr';
    }
  }

  @override
  String toString() => format();
}

extension PartialDateConversion on DateTime {
  PartialDate toPartialDate() => PartialDate(year: year, month: month, day: day);
}

extension DateTimeFromPartialDate on PartialDate {
  DateTime toDateTime() => DateTime(year ?? 2000, month, day);
}
