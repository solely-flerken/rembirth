import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:rembirth/l10n/app_localizations.dart';
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
  Locale get locale {
    Locale locale;
    if (localeCode == null) {
      locale = WidgetsBinding.instance.platformDispatcher.locale;
    } else {
      locale = LocaleUtil.parseLocale(localeCode!);
    }

    final supportedLocales = AppLocalizations.supportedLocales;

    final exactMatch = supportedLocales.firstWhereOrNull(
      (l) => l.languageCode == locale.languageCode && (l.countryCode?.toLowerCase() == locale.countryCode?.toLowerCase()),
    );

    if (exactMatch != null) return exactMatch;

    final languageOnlyMatch = supportedLocales.firstWhere(
          (l) => l.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );

    return languageOnlyMatch;
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
