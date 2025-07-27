import 'package:flutter/material.dart';
import 'package:rembirth/datepicker/util.dart';

class DayPicker extends StatelessWidget {
  final int month;
  final int? year;
  final int? initialDay;
  final void Function(int) onDaySelected;

  const DayPicker({super.key, required this.month, this.year, this.initialDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final int effectiveYear = year ?? 2000;

    final localizations = MaterialLocalizations.of(context);
    final int firstDayOfWeek = localizations.firstDayOfWeekIndex;
    final List<String> localizedOrderedWeekdayHeaders = [
      ...weekdays.sublist(firstDayOfWeek),
      ...weekdays.sublist(0, firstDayOfWeek),
    ];

    final int firstDayOffset = DateUtils.firstDayOffset(effectiveYear, month, localizations);
    final int daysInMonth = DateUtils.getDaysInMonth(effectiveYear, month);
    final int itemCount = 7 + firstDayOffset + daysInMonth;

    final DateTime today = DateTime.now();
    final bool isCurrentMonth = today.month == month && today.year == year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: GridView.builder(
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            // Weekday headers
            if (index < 7) {
              return Center(
                child: Text(localizedOrderedWeekdayHeaders[index], style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }

            // Empty slots before 1st day
            if (index < 7 + firstDayOffset) {
              return const SizedBox.shrink();
            }

            final int day = index - 7 - firstDayOffset + 1;
            final bool isToday = isCurrentMonth && today.day == day;
            final bool isSelected = initialDay == day;

            Color? textColor = Theme.of(context).textTheme.bodyLarge?.color;
            Color? backgroundColor;
            Color borderColor = Colors.transparent;

            if (isSelected) {
              textColor = Colors.white;
              backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
            }
            if (isToday) {
              borderColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onDaySelected(day),
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: borderColor, width: 2),
                ),
                elevation: isToday || isSelected ? 5 : 2,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
