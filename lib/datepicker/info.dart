import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rembirth/datepicker/util.dart';

import 'date_picker_info.dart';

class DatePickerInfoWidget extends StatefulWidget {
  final void Function() onInfoRead;

  const DatePickerInfoWidget({super.key, required this.onInfoRead});

  @override
  State<DatePickerInfoWidget> createState() => _DatePickerInfoWidgetState();
}

class _DatePickerInfoWidgetState extends State<DatePickerInfoWidget> {
  final DateTime selected = DateTime(2015, 3, 14);
  DatePickerStep currentDatePickerStep = DatePickerStep.year;

  List<TextSpan> _buildFormattedDateSpans(BuildContext context) {
    final int currentYear = selected.year;
    final String monthName = months[selected.month]!;
    final int day = selected.day;

    final highlightColor = Theme.of(context).colorScheme.primary;

    return [
      TextSpan(
        text: '$day ',
        style: TextStyle(color: currentDatePickerStep == DatePickerStep.day ? highlightColor : null),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            setState(() => currentDatePickerStep = DatePickerStep.day);
          },
      ),
      TextSpan(
        text: '$monthName ',
        style: TextStyle(color: currentDatePickerStep == DatePickerStep.month ? highlightColor : null),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            setState(() => currentDatePickerStep = DatePickerStep.month);
          },
      ),
      TextSpan(
        text: '$currentYear',
        style: TextStyle(color: currentDatePickerStep == DatePickerStep.year ? highlightColor : null),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            setState(() => currentDatePickerStep = DatePickerStep.year);
          },
      ),
    ];
  }

  String _getCurrentDateText() {
    final now = DateTime.now();

    switch (currentDatePickerStep) {
      case DatePickerStep.day:
        return now.day.toString();
      case DatePickerStep.month:
        return months[now.month]!;
      case DatePickerStep.year:
        return now.year.toString();
      default:
        return '';
    }
  }

  String _getSelectedDateText() {
    switch (currentDatePickerStep) {
      case DatePickerStep.day:
        return selected.day.toString();
      case DatePickerStep.month:
        return months[selected.month]!;
      case DatePickerStep.year:
        return selected.year.toString();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).colorScheme.primary.withAlpha(200);
    Color borderColor = Theme.of(context).colorScheme.secondary.withAlpha(200);
    Color tertiaryColor = Theme.of(context).colorScheme.tertiary.withAlpha(200);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 26),
                  children: _buildFormattedDateSpans(context),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Tap day, month, or year to change the selection',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            DatePickerInfoCard(
              label: 'Currently selected date',
              text: _getSelectedDateText(),
              backgroundColor: primaryColor,
              textColor: Colors.white,
            ),
            DatePickerInfoCard(label: 'Current date', text: _getCurrentDateText(), borderColor: borderColor),
            DatePickerInfoCard(
              label: 'Special value',
              text: 'Unknown',
              backgroundColor: tertiaryColor,
              textColor: Colors.white,
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: widget.onInfoRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), 'Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
