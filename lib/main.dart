import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
import 'package:rembirth/save/isar_save_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/save/save_mode.dart';
import 'package:rembirth/util/logger.dart';

import 'birthday/birthday_list.dart';
import 'notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await IsarDatabase.open([BirthdayEntrySchema, BirthdayEntryCategorySchema]);

  final birthdayEntryService = IsarSaveService<BirthdayEntry>();
  final birthdayEntryCategoryService = IsarSaveService<BirthdayEntryCategory>();

  final saveManagerBirthdayEntry = SaveManager(localService: birthdayEntryService, saveMode: SaveMode.local);
  final saveManagerBirthdayEntryCategory = SaveManager(
    localService: birthdayEntryCategoryService,
    saveMode: SaveMode.local,
  );

  // Notifications
  final notificationService = NotificationService();

  notificationService.onNotificationTap = (birthdayId) {
    logger.d("Tapped on birthday notification with ID: $birthdayId");
  };

  await notificationService.init();
  await notificationService.requestPermissions();

  final allBirthdays = await saveManagerBirthdayEntry.loadAll();
  notificationService.setupScheduledNotificationsFromPrefs(allBirthdays);

  runApp(
    MultiProvider(
      providers: [
        Provider<SaveManager<BirthdayEntry>>.value(value: saveManagerBirthdayEntry),
        Provider<SaveManager<BirthdayEntryCategory>>.value(value: saveManagerBirthdayEntryCategory),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: BirthdayListWidget()));
  }
}
