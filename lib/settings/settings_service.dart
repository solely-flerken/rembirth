import 'package:rembirth/settings/settings_constants.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:rembirth/settings/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultSettings = Settings.defaults();

    final themeName = prefs.getString(kTheme) ?? defaultSettings.theme.name;

    return Settings(
      theme: ThemeSetting.values.firstWhere((e) => e.name == themeName, orElse: () => defaultSettings.theme),
      positionToolbarBottom: prefs.getBool(kPositionToolbarBottom) ?? defaultSettings.positionToolbarBottom,
      notificationsEnabled: prefs.getBool(kNotificationsEnabledKey) ?? defaultSettings.notificationsEnabled,
      notificationTimeHour: prefs.getInt(kNotificationHourKey) ?? defaultSettings.notificationTime.hour,
      notificationTimeMinute: prefs.getInt(kNotificationMinuteKey) ?? defaultSettings.notificationTime.minute,
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(kTheme, settings.theme.name);
    await prefs.setBool(kPositionToolbarBottom, settings.positionToolbarBottom);
    await prefs.setBool(kNotificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setInt(kNotificationHourKey, settings.notificationTimeHour);
    await prefs.setInt(kNotificationMinuteKey, settings.notificationTimeMinute);
  }

  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
