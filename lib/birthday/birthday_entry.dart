import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rembirth/l10n/app_localizations.dart';
import 'package:rembirth/model/birthday_entry.dart';

import '../util/date_util.dart';

class BirthdayEntryTile extends StatelessWidget {
  final BirthdayEntry entry;
  final void Function(BirthdayEntry entry)? onTap;
  final bool isSelected;

  const BirthdayEntryTile({super.key, required this.entry, this.onTap, this.isSelected = false});

  String _formatBirthdayCountdown(BuildContext context, int daysUntil, String weekdayName) {
    final l10n = AppLocalizations.of(context)!;

    if (daysUntil == 0) {
      return l10n.entry_birthday_today;
    } else if (daysUntil == 1) {
      return l10n.entry_birthday_tomorrow(weekdayName);
    } else {
      return l10n.entry_birthday_in_days(daysUntil, weekdayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final now = DateTime.now();
    final int? year = entry.year;
    final int month = entry.month ?? 1;
    final int day = entry.day ?? 1;

    final birthdayDate = DateTime(year ?? 2000, month, day);

    final daysUntil = DateUtil.daysUntilDate(now, birthdayDate);
    final nextBirthdayDate = now.add(Duration(days: daysUntil));

    final locale = Localizations.localeOf(context).toString();
    final weekdayName = DateFormat.EEEE(locale).format(nextBirthdayDate);

    final formatter = DateFormat(year != null ? "yMMMMd" : "MMMMd", locale);
    final String birthdayString = formatter.format(birthdayDate);

    return Card(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(Icons.cake, color: theme.colorScheme.primary),
        title: Text(entry.name ?? l10n.entry_unnamed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(birthdayString),
            const SizedBox(height: 2),
            Text(_formatBirthdayCountdown(context, daysUntil, weekdayName), style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: daysUntil == 0 ? const Icon(Icons.celebration, color: Colors.pinkAccent, size: 28) : null,
        onTap: () => onTap?.call(entry),
      ),
    );
  }
}
