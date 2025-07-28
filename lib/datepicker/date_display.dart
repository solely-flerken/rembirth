import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays a date in a localized format where each part
/// (day, month, year) can be individually styled and made interactive.
class InteractiveDateDisplay extends StatelessWidget {
  final int? year;
  final int? month;
  final int? day;

  final String placeholderText;
  final TextStyle? baseStyle;

  final VoidCallback? onDayTap;
  final VoidCallback? onMonthTap;
  final VoidCallback? onYearTap;

  final TextStyle? dayStyle;
  final TextStyle? monthStyle;
  final TextStyle? yearStyle;

  const InteractiveDateDisplay({
    super.key,
    this.year,
    this.month,
    this.day,
    required this.placeholderText,
    this.baseStyle,
    this.onDayTap,
    this.onMonthTap,
    this.onYearTap,
    this.dayStyle,
    this.monthStyle,
    this.yearStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (year == null && month == null && day == null) {
      return Text(placeholderText, style: baseStyle);
    }

    final locale = Localizations.localeOf(context).toString();

    /// Build skeleton from provided date parts in order: year, month, day
    final skeletonParts = <String>[];
    if (year != null) skeletonParts.add('y');
    if (month != null) skeletonParts.add('MMMM');
    if (day != null) skeletonParts.add('d');

    final formatter = DateFormat(skeletonParts.join(), locale);
    final pattern = formatter.pattern!;

    /// Create DateTime with safe defaults for missing parts
    /// (These won't get displayed, but are needed for a valid DateTime object)
    final dateTime = DateTime(year ?? 2000, month ?? 1, day ?? 1);

    final dayRecognizer = onDayTap != null ? (TapGestureRecognizer()..onTap = onDayTap) : null;
    final monthRecognizer = onMonthTap != null ? (TapGestureRecognizer()..onTap = onMonthTap) : null;
    final yearRecognizer = onYearTap != null ? (TapGestureRecognizer()..onTap = onYearTap) : null;

    final spans = <TextSpan>[];
    int cursor = 0;
    final matches = RegExp(r'[dMyL]+').allMatches(pattern);

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: pattern.substring(cursor, match.start)));
      }

      final subPattern = match.group(0)!;

      /// Only add spans for date parts that were originally provided
      if (subPattern.contains('d') && day != null) {
        spans.add(TextSpan(
          text: DateFormat.d(locale).format(dateTime),
          style: dayStyle,
          recognizer: dayRecognizer,
        ));
      } else if ((subPattern.contains('M') || subPattern.contains('L')) && month != null) {
        spans.add(TextSpan(
          text: DateFormat.MMMM(locale).format(dateTime),
          style: monthStyle,
          recognizer: monthRecognizer,
        ));
      } else if (subPattern.contains('y') && year != null) {
        spans.add(TextSpan(
          text: DateFormat.y(locale).format(dateTime),
          style: yearStyle,
          recognizer: yearRecognizer,
        ));
      }
      cursor = match.end;
    }

    if (cursor < pattern.length) {
      spans.add(TextSpan(text: pattern.substring(cursor)));
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}