import 'package:flutter/material.dart';

class YearPickerWidget extends StatelessWidget {
  final int startYear;
  final int? initialYear;
  final void Function(int?) onYearSelected;

  const YearPickerWidget({super.key, this.startYear = 1950, this.initialYear, required this.onYearSelected});

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;

    // Calculate the total number of years, rounded up to a multiple of 3
    // (to fill the grid rows evenly with 3 columns), then subtract 1
    // to account for the added `null` entry representing "Unknown" year.
    final int yearCount = ((currentYear - startYear + 1 + 2) ~/ 3) * 3 - 1;
    final List<int?> years = [null, ...List.generate(yearCount, (i) => currentYear - i)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: GridView.builder(
          itemCount: years.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final year = years[index];
            final bool isCurrentYear = year == currentYear;
            final bool isSelected = year == initialYear;

            Color? textColor = Theme.of(context).textTheme.bodyLarge?.color;
            Color? backgroundColor;
            Color borderColor = Colors.transparent;

            if (isSelected) {
              textColor = Colors.white;
              backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
            }
            if (isCurrentYear) {
              borderColor = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8);
            }
            if (year == null) {
              textColor = Colors.white;
              backgroundColor = Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onYearSelected(year),
              child: Card(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  side: BorderSide(color: borderColor, width: 3),
                ),
                elevation: isSelected || isCurrentYear ? 5 : 2,
                child: Center(
                  child: Text(
                    year == null ? 'Unknown' : year.toString(),
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
