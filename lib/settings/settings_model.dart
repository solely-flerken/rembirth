import 'package:flutter/material.dart';
import 'package:rembirth/settings/themes.dart';

class Settings {
  ThemeSetting theme;
  bool notificationsEnabled;
  int notificationTimeHour;
  int notificationTimeMinute;

  Settings({
    required this.theme,
    required this.notificationsEnabled,
    required this.notificationTimeHour,
    required this.notificationTimeMinute,
  });

  factory Settings.defaults() {
    return Settings(
      theme: ThemeSetting.system,
      notificationsEnabled: true,
      notificationTimeHour: 9,
      notificationTimeMinute: 0,
    );
  }

  /// Returns the stored time as a TimeOfDay object
  TimeOfDay get notificationTime => TimeOfDay(hour: notificationTimeHour, minute: notificationTimeMinute);

  ThemeMode get themeMode {
    switch (theme) {
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
      case ThemeSetting.system:
        return ThemeMode.system;
    }
  }
}
