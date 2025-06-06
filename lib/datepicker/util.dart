const Map<int, String> months = {
  DateTime.january: 'January',
  DateTime.february: 'February',
  DateTime.march: 'March',
  DateTime.april: 'April',
  DateTime.may: 'May',
  DateTime.june: 'June',
  DateTime.july: 'July',
  DateTime.august: 'August',
  DateTime.september: 'September',
  DateTime.october: 'October',
  DateTime.november: 'November',
  DateTime.december: 'December',
};

const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

enum DatePickerStep {
  info(0),
  year(1),
  month(2),
  day(3);

  final int pageIndex;

  const DatePickerStep(this.pageIndex);

  static DatePickerStep fromIndex(int index) {
    return DatePickerStep.values.firstWhere((e) => e.pageIndex == index);
  }
}
