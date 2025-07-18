import 'package:flutter/material.dart';
import 'package:rembirth/datepicker/util.dart';

class MonthPicker extends StatelessWidget {
  final int? initialMonth;
  final void Function(int) onMonthSelected;

  const MonthPicker({super.key, this.initialMonth, required this.onMonthSelected});

  @override
  Widget build(BuildContext context) {
    final int currentMonth = DateTime.now().month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: GridView.builder(
          itemCount: months.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            // +1 because DateTime.January = 1 and index start at 0
            final int month = index + 1;
            final String monthName = months[month]!;

            final bool isCurrentMonth = month == currentMonth;
            final bool isSelected = month == initialMonth;

            Color? textColor = Theme.of(context).textTheme.bodyLarge?.color;
            Color? backgroundColor;
            Color borderColor = Colors.transparent;

            if (isSelected) {
              textColor = Colors.white;
              backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
            }
            if (isCurrentMonth) {
              borderColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onMonthSelected(month),
              child: Card(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(color: borderColor, width: 3),
                ),
                elevation: isSelected || isCurrentMonth ? 5 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        monthName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
                      ),
                    ),
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
