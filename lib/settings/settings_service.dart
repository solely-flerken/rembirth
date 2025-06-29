import 'package:rembirth/settings/settings_constants.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:rembirth/settings/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(kTheme) ?? ThemeSetting.system.name;

    return Settings(
      theme: ThemeSetting.values.firstWhere((e) => e.name == themeName, orElse: () => ThemeSetting.system),
      notificationsEnabled: prefs.getBool(kNotificationsEnabledKey) ?? true,
      notificationTimeHour: prefs.getInt(kNotificationHourKey) ?? 9,
      notificationTimeMinute: prefs.getInt(kNotificationMinuteKey) ?? 0,
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(kTheme, settings.theme.name);
    await prefs.setBool(kNotificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setInt(kNotificationHourKey, settings.notificationTimeHour);
    await prefs.setInt(kNotificationMinuteKey, settings.notificationTimeMinute);
  }
}
