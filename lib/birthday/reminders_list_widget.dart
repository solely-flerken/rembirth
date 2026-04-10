import 'package:flutter/material.dart';
import 'package:rembirth/notifications/notification_constants.dart';

import '../l10n/app_localizations.dart';

class _Preset {
  final int days;
  final String label;

  const _Preset({required this.days, required this.label});
}

class RemindersListWidget extends StatelessWidget {
  final List<int> reminders;
  final void Function(List<int>) onRemindersChanged;

  const RemindersListWidget({super.key, required this.reminders, required this.onRemindersChanged});

  bool get _isAtMax => reminders.length >= maxRemindersPerEntry;

  void _togglePreset(int days) {
    if (days == 0) return;

    final List<int> updated;
    if (reminders.contains(days)) {
      updated = reminders.where((d) => d != days).toList();
    } else {
      if (_isAtMax) return;
      updated = [...reminders, days]..sort();
    }
    onRemindersChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final List<_Preset> presets = [
      _Preset(days: 0, label: l10n.reminder_on_birthday),
      _Preset(days: 1, label: l10n.reminder_1_day_before),
      _Preset(days: 3, label: l10n.reminder_3_days_before),
      _Preset(days: 7, label: l10n.reminder_1_week_before),
      _Preset(days: 30, label: l10n.reminder_1_month_before),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l10n.reminders_label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Column(
            children: presets.map((preset) {
              final isLocked = preset.days == 0;
              final isOn = isLocked || reminders.contains(preset.days);
              final canToggleOn = !_isAtMax || isOn;

              return SwitchListTile.adaptive(
                title: Text(preset.label),
                value: isOn,
                onChanged: isLocked || !canToggleOn
                    ? null
                    : (_) => _togglePreset(preset.days),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
