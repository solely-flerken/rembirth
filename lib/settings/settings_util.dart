import 'package:flutter/material.dart';
import 'package:rembirth/settings/setting_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsUtil {
  static Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();

    final int hour = prefs.getInt(kNotificationHourKey) ?? 9;
    final int minute = prefs.getInt(kNotificationMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
