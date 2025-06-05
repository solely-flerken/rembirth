class PartialDate {
  final int? year; // nullable
  final int month;
  final int day;

  PartialDate({this.year, required this.month, required this.day});
}

extension PartialDateConversion on DateTime {
  PartialDate toPartialDate() => PartialDate(year: year, month: month, day: day);
}

extension DateTimeFromPartialDate on PartialDate {
  DateTime toDateTime() => DateTime(year ?? 2000, month, day);
}
