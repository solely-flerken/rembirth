import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:rembirth/l10n/app_localizations.dart';
import 'package:rembirth/notifications/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../model/birthday_entry.dart';
import '../settings/settings_constants.dart';
import '../util/date_util.dart';
import '../util/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  AppLocalizations? _l10n;

  Future<void> setLocale(Locale locale) async {
    _l10n = await AppLocalizations.delegate.load(locale);
    logger.i("NotificationService: Locale set to ${locale.languageCode}");
  }

  AppLocalizations get l10n {
    if (_l10n == null) {
      throw Exception("NotificationService: l10n not initialized. Call setLocale() first.");
    }
    return _l10n!;
  }

  void Function(int)? onNotificationTap;

  Future<void> init() async {
    await _initializeTimeZone();

    const androidSettings = AndroidInitializationSettings(kNotificationIcon);
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final birthdayId = data['id'] as int;
            onNotificationTap?.call(birthdayId);
          } catch (e) {
            logger.d('Failed to decode notification payload: $e');
          }
        }
      },
    );
  }

  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'birthday_channel_id',
        'Birthday Reminders',
        channelDescription: 'Channel for birthday notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: kNotificationIcon,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
  }

  static int _getNotificationId(int entryId, int slotIndex){
    return (entryId * maxRemindersPerEntry) + slotIndex;
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> setupScheduledNotificationsFromPrefs(List<BirthdayEntry> birthdays) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? true;

    if (!notificationsEnabled) {
      logger.i("Notifications are disabled. Skipping scheduling on startup.");
      return;
    }

    final hour = prefs.getInt(kNotificationHourKey) ?? 9;
    final minute = prefs.getInt(kNotificationMinuteKey) ?? 0;
    final notificationTime = TimeOfDay(hour: hour, minute: minute);

    logger.i("Scheduling all notifications for ${DateUtil.formatTimeOfDay(notificationTime)}");

    await rescheduleAllNotifications(birthdays, notificationTime: notificationTime);
  }

  Future<void> scheduleBirthdayNotification(
    BirthdayEntry entry, {
    TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0),
    bool testMode = false,
  }) async {
    await cancelBirthdayNotification(entry);
    final reminders = entry.reminders ?? [0];
    for (int i = 0; i < reminders.length && i < maxRemindersPerEntry; i++) {
      try {
        await _scheduleNotification(entry, reminders[i], i, notificationTime, testMode);
      } catch (e) {
        logger.d('Error scheduling notification for ${entry.name} (${reminders[i]} days before): $e');
      }
    }
  }

  Future<void> _scheduleNotification(
    BirthdayEntry birthday,
    int daysBefore,
    int slotIndex,
    TimeOfDay notificationTime,
    bool testMode,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final notificationId = _getNotificationId(birthday.id, slotIndex);
    late tz.TZDateTime scheduledDate;

    if (testMode) {
      scheduledDate = now.add(const Duration(seconds: 5));
    } else {
      final birthdayThisYear = DateTime(now.year, birthday.month!, birthday.day!);
      final targetDate = birthdayThisYear.subtract(Duration(days: daysBefore));

      scheduledDate = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        notificationTime.hour,
        notificationTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        final birthdayNextYear = DateTime(now.year + 1, birthday.month!, birthday.day!);
        final targetDateNextYear = birthdayNextYear.subtract(Duration(days: daysBefore));
        scheduledDate = tz.TZDateTime(
          tz.local,
          targetDateNextYear.year,
          targetDateNextYear.month,
          targetDateNextYear.day,
          notificationTime.hour,
          notificationTime.minute,
        );
      }
    }

    final String title;
    final String body;
    if (daysBefore == 0) {
      title = l10n.notification_birthday_today_title(birthday.name ?? "");
      body = l10n.notification_birthday_today_body;
    } else {
      final unit = daysBefore == 1 ? l10n.day_singular : l10n.day_plural;
      title = l10n.notification_birthday_upcoming_title(birthday.name ?? "", daysBefore, unit);
      body = l10n.notification_birthday_upcoming_body;
    }

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      payload: jsonEncode({'id': birthday.id}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    logger.i('Scheduled notification for ${birthday.name} on $scheduledDate ($daysBefore days before)');
  }

  Future<void> cancelBirthdayNotification(BirthdayEntry entry) async {
    for (int i = 0; i < maxRemindersPerEntry; i++) {
      await _plugin.cancel(_getNotificationId(entry.id, i));
    }

    logger.i('Cancelled all notifications for birthday ID: ${entry.id}');
  }

  Future<void> rescheduleAllNotifications(
    List<BirthdayEntry> birthdays, {
    TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    await _plugin.cancelAll();
    for (final birthday in birthdays) {
      try {
        await scheduleBirthdayNotification(birthday, notificationTime: notificationTime);
      } catch (e) {
        logger.d('Error rescheduling ${birthday.name}: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    logger.i("Cancelled all scheduled notifications.");
  }
}
