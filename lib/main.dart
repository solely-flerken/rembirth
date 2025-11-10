import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/l10n/app_localizations.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
import 'package:rembirth/save/isar_save_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/save/save_mode.dart';
import 'package:rembirth/settings/settings_controller.dart';
import 'package:rembirth/settings/settings_model.dart';
import 'package:rembirth/settings/settings_service.dart';
import 'package:rembirth/util/logger.dart';
import 'package:workmanager/workmanager.dart';

import 'birthday/birthday_list.dart';
import 'notifications/notification_service.dart';

const rescheduleTask = "rescheduleNotificationsTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == rescheduleTask) {
      await IsarDatabase.open([BirthdayEntrySchema, BirthdayEntryCategorySchema]);
      final birthdayEntryService = IsarSaveService<BirthdayEntry>();
      final saveManagerBirthdayEntry = SaveManager(localService: birthdayEntryService, saveMode: SaveMode.local);
      final notificationService = NotificationService();

      // Initialize notifications
      await notificationService.init();

      // Load birthdays and reschedule
      final allBirthdays = await saveManagerBirthdayEntry.loadAll();
      await notificationService.setupScheduledNotificationsFromPrefs(allBirthdays);
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager and register the task
  await Workmanager().initialize(callbackDispatcher);

  // Register the task to run periodically
  Workmanager().registerPeriodicTask(
    "1",
    rescheduleTask,
    frequency: const Duration(days: 1),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresCharging: false,
    ),
  );

  // Initialize database
  await IsarDatabase.open([BirthdayEntrySchema, BirthdayEntryCategorySchema]);

  // Create services
  final birthdayEntryService = IsarSaveService<BirthdayEntry>();
  final birthdayEntryCategoryService = IsarSaveService<BirthdayEntryCategory>();

  final saveManagerBirthdayEntry = SaveManager(localService: birthdayEntryService, saveMode: SaveMode.local);
  final saveManagerBirthdayEntryCategory = SaveManager(
    localService: birthdayEntryCategoryService,
    saveMode: SaveMode.local,
  );

  final notificationService = NotificationService();

  // Load settings from SharedPreferences
  final settings = await SettingsService.loadSettings();
  final settingsController = SettingsController(
    settings: settings,
    notificationService: notificationService,
    birthdaySaveManager: saveManagerBirthdayEntry,
  );

  // Notifications setup
  await notificationService.init();
  await notificationService.requestPermissions();
  notificationService.onNotificationTap = (birthdayId) {
    logger.d("Tapped on birthday notification with ID: $birthdayId");
  };

  final allBirthdays = await saveManagerBirthdayEntry.loadAll();
  notificationService.setupScheduledNotificationsFromPrefs(allBirthdays);

  runApp(
    MultiProvider(
      providers: [
        Provider<SaveManager<BirthdayEntry>>.value(value: saveManagerBirthdayEntry),
        Provider<SaveManager<BirthdayEntryCategory>>.value(value: saveManagerBirthdayEntryCategory),
        Provider<NotificationService>.value(value: notificationService),
        Provider<Settings>.value(value: settings),

        ChangeNotifierProvider<SettingsController>.value(value: settingsController),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    final settingsController = context.read<SettingsController>();
    if (settingsController.settings.localeCode == null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return MaterialApp(
      locale: settingsController.settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: settingsController.settings.themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: const Scaffold(body: BirthdayListWidget()),
    );
  }
}
