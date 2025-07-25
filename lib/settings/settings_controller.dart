import 'package:flutter/material.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:rembirth/settings/settings_service.dart';
import 'package:rembirth/settings/themes.dart';

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

  Future<void> setTheme(ThemeSetting theme) async {
    if (_settings.theme == theme) return;
    _settings.theme = theme;
    await _saveAndNotify();
  }

  Future<void> setLanguage(String? newLanguageCode) async {
    if (_settings.languageCode == newLanguageCode) return;
    _settings.languageCode = newLanguageCode;
    await _saveAndNotify();
  }

  Future<void> setPositionToolbarBottom(bool pushToBottom) async {
    if (_settings.positionToolbarBottom == pushToBottom) return;
    _settings.positionToolbarBottom = pushToBottom;
    await _saveAndNotify();
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
    if (_settings.notificationTime == newTime || !_settings.notificationsEnabled) return;

    _settings.notificationTimeHour = newTime.hour;
    _settings.notificationTimeMinute = newTime.minute;

    logger.i("Notification time changed. Rescheduling all birthdays...");

    final allBirthdays = await _birthdaySaveManager.loadAll();
    await _notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: newTime);

    await _saveAndNotify();
  }

  Future<void> restoreDefaults() async {
    final defaultSettings = Settings.defaults();

    final shouldRescheduleNotifications = _settings.notificationTime != defaultSettings.notificationTime;

    _settings.theme = defaultSettings.theme;
    _settings.positionToolbarBottom = defaultSettings.positionToolbarBottom;
    _settings.languageCode = defaultSettings.languageCode;
    _settings.notificationsEnabled = defaultSettings.notificationsEnabled;
    _settings.notificationTimeHour = defaultSettings.notificationTimeHour;
    _settings.notificationTimeMinute = defaultSettings.notificationTimeMinute;

    if (_settings.notificationsEnabled && shouldRescheduleNotifications) {
      logger.i("Restoring defaults: Notifications are enabled, rescheduling...");
      final allBirthdays = await _birthdaySaveManager.loadAll();
      await _notificationService.rescheduleAllNotifications(allBirthdays, notificationTime: _settings.notificationTime);
    } else if (_settings.notificationsEnabled && !shouldRescheduleNotifications) {
      logger.i("Restoring defaults: Default notification settings already used...");
    } else {
      logger.i("Restoring defaults: Notifications are disabled, cancelling all...");
      await _notificationService.cancelAllNotifications();
    }

    await SettingsService.clearSettings();
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await SettingsService.saveSettings(_settings);
    notifyListeners();
  }
}
