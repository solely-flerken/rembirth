import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../model/birthday_entry.dart';
import '../util/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  void Function(int)? onNotificationTap;

  Future<void> init() async {
    await _initializeTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  Future<void> scheduleBirthdayNotification(
    BirthdayEntry birthday, {
    TimeOfDay notificationTime = const TimeOfDay(hour: 9, minute: 0),
    bool testMode = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    late tz.TZDateTime scheduledDate;

    if (testMode) {
      scheduledDate = now.add(const Duration(seconds: 5));
    } else {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        birthday.month!,
        birthday.day!,
        notificationTime.hour,
        notificationTime.minute,
      );

      // If the birthday this year has already passed, schedule for next year
      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(
          tz.local,
          now.year + 1,
          birthday.month!,
          birthday.day!,
          notificationTime.hour,
          notificationTime.minute,
        );
      }
    }

    await _plugin.zonedSchedule(
      birthday.id,
      "It's ${birthday.name}'s Birthday! 🎂",
      "Don't forget to send your best wishes today.",
      scheduledDate,
      _notificationDetails(),
      payload: jsonEncode({'id': birthday.id}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    logger.i('Scheduled notification for ${birthday.name} on $scheduledDate');
  }

  Future<void> cancelBirthdayNotification(int birthdayId) async {
    await _plugin.cancel(birthdayId);
    logger.i('Cancelled notification for birthday ID: $birthdayId');
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

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
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

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'birthday_channel_id',
        'Birthday Reminders',
        channelDescription: 'Channel for birthday notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
  }
}
