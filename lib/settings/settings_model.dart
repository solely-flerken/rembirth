import 'package:flutter/material.dart';

class Settings {
  bool isDarkMode;
  bool notificationsEnabled;
  int notificationTimeHour;
  int notificationTimeMinute;

  Settings({
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.notificationTimeHour,
    required this.notificationTimeMinute,
  });

  /// Returns the stored time as a TimeOfDay object
  TimeOfDay get notificationTime => TimeOfDay(hour: notificationTimeHour, minute: notificationTimeMinute);
}
