import 'package:flutter/material.dart';
import 'package:rembirth/settings/themes.dart';
import 'package:rembirth/util/locale_util.dart';

class Settings {
  ThemeSetting theme;
  bool positionToolbarBottom;
  bool notificationsEnabled;
  int notificationTimeHour;
  int notificationTimeMinute;
  String? localeCode;

  Settings({
    required this.theme,
    required this.positionToolbarBottom,
    required this.notificationsEnabled,
    required this.notificationTimeHour,
    required this.notificationTimeMinute,
    required this.localeCode,
  });

  factory Settings.defaults() {
    return Settings(
      theme: ThemeSetting.system,
      positionToolbarBottom: false,
      notificationsEnabled: true,
      notificationTimeHour: 9,
      notificationTimeMinute: 0,
      localeCode: null,
    );
  }

  /// Returns the stored time as a TimeOfDay object
  TimeOfDay get notificationTime => TimeOfDay(hour: notificationTimeHour, minute: notificationTimeMinute);

  /// Returns a Locale object based on the saved locale code
  Locale? get locale {
    if (localeCode == null) return null;
    return LocaleUtil.parseLocale(localeCode!);
  }

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
