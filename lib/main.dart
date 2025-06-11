import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
import 'package:rembirth/save/isar_save_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/save/save_mode.dart';

import 'birthday/birthday_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await IsarDatabase.open([BirthdayEntrySchema, BirthdayEntryCategorySchema]);

  final birthdayEntryService = IsarSaveService<BirthdayEntry>();
  final birthdayEntryCategoryService = IsarSaveService<BirthdayEntryCategory>();

  final saveManagerBirthdayEntry = SaveManager(localService: birthdayEntryService, saveMode: SaveMode.local);
  final saveManagerBirthdayEntryCategory = SaveManager(
    localService: birthdayEntryCategoryService,
    saveMode: SaveMode.local,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SaveManager<BirthdayEntry>>.value(value: saveManagerBirthdayEntry),
        Provider<SaveManager<BirthdayEntryCategory>>.value(value: saveManagerBirthdayEntryCategory),
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
