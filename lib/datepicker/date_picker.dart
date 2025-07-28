import 'package:flutter/material.dart';
import 'package:rembirth/datepicker/info.dart';
import 'package:rembirth/datepicker/partial_date.dart';
import 'package:rembirth/datepicker/util.dart';
import 'package:rembirth/l10n/app_localizations.dart';
import 'date_display.dart';
import 'year_picker.dart';
import 'month_picker.dart';
import 'day_picker.dart';

class CustomDatePicker extends StatefulWidget {
  final DatePickerStep initialStep;
  final DatePickerStep? stopStep;
  final PartialDate? initialDate;

  const CustomDatePicker({
    super.key,
    this.initialStep = DatePickerStep.year,
    this.stopStep,
    this.initialDate,
  });

  static Future<PartialDate?> show(
    BuildContext context, {
    DatePickerStep initialStep = DatePickerStep.year,
    DatePickerStep? stopStep,
    PartialDate? initialDate,
  }) {
    return showDialog<PartialDate>(
      context: context,
      builder: (_) => CustomDatePicker(initialStep: initialStep, stopStep: stopStep, initialDate: initialDate),
    );
  }

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late PageController _controller;
  late int _initialPageIndex;

  int? selectedYear;
  int? selectedMonth;
  int? selectedDay;

  DatePickerStep? currentDatePickerStep;
  DatePickerStep? stopStep;
  DatePickerStep? _previousStepBeforeInfo;

  final List<DatePickerStep> _history = [];

  @override
  void initState() {
    super.initState();

    currentDatePickerStep = widget.initialStep;
    stopStep = widget.stopStep ?? DatePickerStep.day;

    _history.add(currentDatePickerStep!);

    if (widget.initialDate != null) {
      selectedYear = widget.initialDate!.year;
      selectedMonth = widget.initialDate!.month;
      selectedDay = widget.initialDate!.day;
    } else {
      // If no initialDate, apply defaults
      if (currentDatePickerStep == DatePickerStep.month || currentDatePickerStep == DatePickerStep.day) {
        // Default year when starting on month/day and no initialDate
        selectedYear = 2000;
      }
      if (currentDatePickerStep == DatePickerStep.day) {
        // Default month when starting on day and no initialDate
        selectedMonth = 1;
      }
    }

    // Determine the starting page index for the PageView
    _initialPageIndex = currentDatePickerStep!.pageIndex;

    _controller = PageController(initialPage: _initialPageIndex);

    _controller.addListener(() {
      final newIndex  = _controller.page?.round();
      if (newIndex  == null) return;

      final newStep = DatePickerStep.fromIndex(newIndex);
      if (newStep == currentDatePickerStep) return;

      // If we jump to a step already in our history,
      // we remove all the steps that came after it.
      // Otherwise, it's a new forward step.
      if (_history.contains(newStep)) {
        final indexInHistory = _history.indexOf(newStep);
        _history.removeRange(indexInHistory + 1, _history.length);
      } else {
        _history.add(newStep);
      }

      setState(() {
        currentDatePickerStep = newStep;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _stepBack() {
    if (_history.length > 1) {
      _history.removeLast();
      _controller.jumpToPage(_history.last.pageIndex);
    }
  }

  void _nextPage() async {
    // Page 0: Info, Page 1: Year, Page 2: Month, Page 3: Day
    if (currentDatePickerStep == stopStep) {
      // Delay closing for visual feedback
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;
      Navigator.pop(context, PartialDate(year: selectedYear, month: selectedMonth!, day: selectedDay!));
      return;
    }

    if (_controller.page! < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
    }
  }

  void _onInfoRead() {
    if (_previousStepBeforeInfo != null) {
      _controller.jumpToPage(_previousStepBeforeInfo!.pageIndex);
      _previousStepBeforeInfo = null;
    } else {
      _nextPage();
    }
  }

  void _onYearSelected(int? year) {
    setState(() {
      selectedYear = year;

      // Clamp day to valid date for new month/year
      if (selectedMonth != null && selectedDay != null) {
        final maxDay = DateUtils.getDaysInMonth(selectedYear ?? 2000, selectedMonth ?? 1);
        if (selectedDay! > maxDay) {
          selectedDay = maxDay;
        }
      }
    });
    _nextPage();
  }

  void _onMonthSelected(int month) {
    setState(() {
      selectedMonth = month;

      // Clamp day to valid date for new month
      if (selectedDay != null) {
        final maxDay = DateUtils.getDaysInMonth(selectedYear ?? 2000, month);
        if (selectedDay! > maxDay) {
          selectedDay = maxDay;
        }
      }
    });
    _nextPage();
  }

  void _onDaySelected(int day) {
    setState(() => selectedDay = day);
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (bool didPop, PartialDate? result) {
        if (didPop) {
          return;
        }
        _stepBack();
      },
      child: Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        child: SizedBox(
          width: double.maxFinite,
          height: 560,
          child: Column(
            children: [
              // Date display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: InteractiveDateDisplay(
                          year: selectedYear,
                          month: selectedMonth,
                          day: selectedDay,
                          placeholderText: currentDatePickerStep == DatePickerStep.info ? l10n.info_label : l10n.select_a_date,
                          baseStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 26),
                          dayStyle: TextStyle(color: currentDatePickerStep == DatePickerStep.day ? Theme.of(context).colorScheme.primary : null),
                          monthStyle: TextStyle(color: currentDatePickerStep == DatePickerStep.month ? Theme.of(context).colorScheme.primary : null),
                          yearStyle: TextStyle(color: currentDatePickerStep == DatePickerStep.year ? Theme.of(context).colorScheme.primary : null),
                          onDayTap: () {
                            if (selectedYear != null && selectedMonth != null) {
                              _controller.jumpToPage(DatePickerStep.day.pageIndex);
                            }
                          },
                          onMonthTap: () {
                            if (selectedYear != null) {
                              _controller.jumpToPage(DatePickerStep.month.pageIndex);
                            }
                          },
                          onYearTap: () => _controller.jumpToPage(DatePickerStep.year.pageIndex),
                        ),
                      ),

                      // Info button
                      if (currentDatePickerStep != DatePickerStep.info)
                        Positioned(
                          right: -8,
                          top: 0,
                          bottom: 0,
                          child: Material(
                            type: MaterialType.transparency,
                            shape: const CircleBorder(),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                _previousStepBeforeInfo = currentDatePickerStep;
                                _controller.jumpToPage(DatePickerStep.info.pageIndex);
                              },
                              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.info_outline, size: 24)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Splitter
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: const Divider(thickness: 2)),

              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    DatePickerInfoWidget(onInfoRead: () => _onInfoRead()),
                    YearPickerWidget(
                      startYear: 1900,
                      initialYear: selectedYear,
                      key: const ValueKey('YearPicker'),
                      onYearSelected: _onYearSelected,
                    ),
                    MonthPicker(
                      initialMonth: selectedMonth,
                      key: const ValueKey('MonthPicker'),
                      onMonthSelected: _onMonthSelected,
                    ),
                    if (selectedMonth != null)
                      DayPicker(
                        year: selectedYear,
                        month: selectedMonth!,
                        initialDay: selectedDay,
                        key: const ValueKey('DayPicker'),
                        onDaySelected: _onDaySelected,
                      ),
                  ].whereType<Widget>().toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
