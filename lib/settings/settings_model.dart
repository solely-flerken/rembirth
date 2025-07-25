import 'package:flutter/material.dart';
import 'package:rembirth/settings/themes.dart';

class Settings {
  ThemeSetting theme;
  bool positionToolbarBottom;
  bool notificationsEnabled;
  int notificationTimeHour;
  int notificationTimeMinute;
  String? languageCode;

  Settings({
    required this.theme,
    required this.positionToolbarBottom,
    required this.notificationsEnabled,
    required this.notificationTimeHour,
    required this.notificationTimeMinute,
    required this.languageCode,
  });

  factory Settings.defaults() {
    return Settings(
      theme: ThemeSetting.system,
      positionToolbarBottom: false,
      notificationsEnabled: true,
      notificationTimeHour: 9,
      notificationTimeMinute: 0,
      languageCode: null,
    );
  }

  /// Returns the stored time as a TimeOfDay object
  TimeOfDay get notificationTime => TimeOfDay(hour: notificationTimeHour, minute: notificationTimeMinute);

  /// Returns a Locale object based on the saved language code
  Locale? get locale => languageCode != null ? Locale(languageCode!) : null;

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
