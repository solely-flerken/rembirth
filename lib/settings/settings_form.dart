import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/settings/setting_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/birthday_entry.dart';
import '../notifications/notification_service.dart';
import '../save/save_manager.dart';
import '../util/logger.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  @override
  State<SettingsPageWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPageWidget> {
  String? _statusMessage;

  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? true;

      final hour = prefs.getInt(kNotificationHourKey) ?? _notificationTime.hour;
      final minute = prefs.getInt(kNotificationMinuteKey) ?? _notificationTime.minute;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationsEnabledKey, _notificationsEnabled);
    await prefs.setInt(kNotificationHourKey, _notificationTime.hour);
    await prefs.setInt(kNotificationMinuteKey, _notificationTime.minute);
  }

  void _updateStatus(String? message) {
    setState(() {
      _statusMessage = message;
    });

    if (_statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage!),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
          ),
        );

        _updateStatus(null);
      });
    }
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(context: context, initialTime: _notificationTime);

    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });

      await _saveSettings();

      if (!mounted) return;

      logger.i("Notification time changed. Rescheduling all birthdays...");

      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final birthdaySaveManager = Provider.of<SaveManager<BirthdayEntry>>(context, listen: false);

      final allBirthdays = await birthdaySaveManager.loadAll();

      await notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: _notificationTime);

      if (!mounted) return;

      _updateStatus("Notification time set to ${picked.format(context)}");
    }
  }

  Future<void> _notificationsEnabledChanged(bool isEnabled) async {
    setState(() {
      _notificationsEnabled = isEnabled;
    });

    _saveSettings();

    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final birthdaySaveManager = Provider.of<SaveManager<BirthdayEntry>>(context, listen: false);

    if (isEnabled) {
      logger.i("Enabling notifications. Rescheduling all birthdays...");

      final allBirthdays = await birthdaySaveManager.loadAll();
      await notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: _notificationTime);
    } else {
      logger.i("Disabling notifications. Cancelling all...");

      await notificationService.cancelAllNotifications();
    }

    _updateStatus("Notifications ${isEnabled ? "enabled" : "disabled"}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: _notificationsEnabledChanged,
          ),
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(_notificationTime.format(context)),
            trailing: const Icon(Icons.schedule, size: 32),
            onTap: _notificationsEnabled ? _pickNotificationTime : null,
          ),
          const Divider(),
          ListTile(title: const Text('About'), subtitle: const Text('Rembirth v1.0.0'), onTap: () => {}),
        ],
      ),
    );
  }
}
