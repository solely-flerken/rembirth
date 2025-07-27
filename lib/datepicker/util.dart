const List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
