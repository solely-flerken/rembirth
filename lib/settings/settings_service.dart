import 'package:rembirth/settings/setting_constants.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return Settings(
      isDarkMode: prefs.getBool(kDarkModeEnabledKey) ?? false,
      notificationsEnabled: prefs.getBool(kNotificationsEnabledKey) ?? true,
      notificationTimeHour: prefs.getInt(kNotificationHourKey) ?? 9,
      notificationTimeMinute: prefs.getInt(kNotificationMinuteKey) ?? 0,
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(kDarkModeEnabledKey, settings.isDarkMode);
    await prefs.setBool(kNotificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setInt(kNotificationHourKey, settings.notificationTimeHour);
    await prefs.setInt(kNotificationMinuteKey, settings.notificationTimeMinute);
  }
}
