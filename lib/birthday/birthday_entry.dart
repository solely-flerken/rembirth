import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rembirth/model/birthday_entry.dart';

import '../util/date_util.dart';

class BirthdayEntryTile extends StatelessWidget {
  final BirthdayEntry entry;
  final void Function(BirthdayEntry entry)? onTap;
  final bool isSelected;

  const BirthdayEntryTile({super.key, required this.entry, this.onTap, this.isSelected = false});

  String _formatBirthdayCountdown(int daysUntil, String weekdayName) {
    if (daysUntil == 0) {
      return "Birthday is today";
    } else if (daysUntil == 1) {
      return "Tomorrow on $weekdayName";
    } else {
      return "In $daysUntil days on $weekdayName";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final int? year = entry.year;
    final int month = entry.month ?? 1;
    final int day = entry.day ?? 1;

    final birthdayDate = DateTime(year ?? now.year, month, day);

    final daysUntil = DateUtil.daysUntilDate(now, birthdayDate);
    final nextBirthdayDate = now.add(Duration(days: daysUntil));

    final weekdayName = DateFormat.EEEE().format(nextBirthdayDate);
    final monthName = DateUtil.getLocalizedMonthName(context, month);

    final birthdayString = year != null ? "$day $monthName $year" : "$day $monthName";

    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.cake, color: theme.colorScheme.primary),
        title: Text(entry.name ?? "Unnamed", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(birthdayString),
            const SizedBox(height: 2),
            Text(_formatBirthdayCountdown(daysUntil, weekdayName), style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: daysUntil == 0 ? const Icon(Icons.celebration, color: Colors.pinkAccent, size: 28) : null,
        onTap: () => onTap?.call(entry),
      ),
    );
  }
}
