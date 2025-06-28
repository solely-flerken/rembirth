import 'package:flutter/material.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:rembirth/settings/settings_service.dart';

import '../model/birthday_entry.dart';
import '../notifications/notification_service.dart';
import '../save/save_manager.dart';
import '../util/logger.dart';

class SettingsController extends ChangeNotifier {
  final Settings _settings;

  final NotificationService _notificationService;
  final SaveManager<BirthdayEntry> _birthdaySaveManager;

  SettingsController({
    required Settings settings,
    required NotificationService notificationService,
    required SaveManager<BirthdayEntry> birthdaySaveManager,
  }) : _settings = settings,
       _notificationService = notificationService,
       _birthdaySaveManager = birthdaySaveManager;

  Settings get settings => _settings;

  void setDarkModeEnabled(bool enabled) {
    if (_settings.isDarkMode == enabled) return;
    _settings.isDarkMode = enabled;
    _saveAndNotify();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_settings.notificationsEnabled == enabled) return;
    _settings.notificationsEnabled = enabled;

    if (enabled) {
      logger.i("Enabling notifications. Rescheduling all birthdays...");

      final allBirthdays = await _birthdaySaveManager.loadAll();
      await _notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: _settings.notificationTime);
    } else {
      logger.i("Disabling notifications. Cancelling all...");

      await _notificationService.cancelAllNotifications();
    }

    await _saveAndNotify();
  }

  Future<void> updateNotificationTime(TimeOfDay newTime) async {
    _settings.notificationTimeHour = newTime.hour;
    _settings.notificationTimeMinute = newTime.minute;

    logger.i("Notification time changed. Rescheduling all birthdays...");

    final allBirthdays = await _birthdaySaveManager.loadAll();
    await _notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: newTime);

    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }
}
